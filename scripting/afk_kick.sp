#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <autoexecconfig>
#include <afk_manager>

#define PLUGIN_VERSION "1.0.0"

#define WARN_INTERVAL 5

Handle g_hKickTimer[MAXPLAYERS + 1];

ConVar g_hCvarEnabled;
ConVar g_hCvarKickTime;
ConVar g_hCvarWarnTime;
ConVar g_hCvarMinPlayers;
ConVar g_hCvarPrefix;
ConVar g_hCvarImmunityFlag;

char g_sPrefix[32];
char g_sImmunityFlag[32];
int g_iKickTime;
int g_iWarnTime;
int g_iMinPlayers;

public Plugin myinfo = {
  name = "[TF2] AFK Kick", 
  author = "ampere", 
  description = "Kicks AFK players after a configurable time.", 
  version = PLUGIN_VERSION, 
  url = "http://github.com/maxijabase"
};

public void OnPluginStart() {
  AutoExecConfig_SetCreateFile(true);
  AutoExecConfig_SetFile("afk_kick");
  
  g_hCvarEnabled = AutoExecConfig_CreateConVar("sm_afk_kick_enable", "1", "Enable AFK kick? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", FCVAR_NONE, true, 0.0, true, 1.0);
  g_hCvarKickTime = AutoExecConfig_CreateConVar("sm_afk_kick_time", "120", "Total AFK seconds before a player is kicked. [0 = DISABLED, DEFAULT: 120]", FCVAR_NONE, true, 0.0);
  g_hCvarWarnTime = AutoExecConfig_CreateConVar("sm_afk_kick_warn_time", "30", "Seconds remaining before kick when warnings start. [DEFAULT: 30]", FCVAR_NONE, true, 0.0);
  g_hCvarMinPlayers = AutoExecConfig_CreateConVar("sm_afk_kick_min_players", "6", "Minimum connected players for AFK kick to be active. [DEFAULT: 6]", FCVAR_NONE, true, 0.0);
  g_hCvarPrefix = AutoExecConfig_CreateConVar("sm_afk_kick_prefix", "AFK Manager", "Chat message prefix.");
  g_hCvarImmunityFlag = AutoExecConfig_CreateConVar("sm_afk_kick_immunity_flag", "", "Admin flag(s) that grant kick immunity. Leave blank to disable.");
  
  AutoExecConfig_CleanFile();
  AutoExecConfig_ExecuteFile();
  
  g_hCvarKickTime.AddChangeHook(OnCvarChanged);
  g_hCvarWarnTime.AddChangeHook(OnCvarChanged);
  g_hCvarMinPlayers.AddChangeHook(OnCvarChanged);
  g_hCvarPrefix.AddChangeHook(OnCvarChanged);
  g_hCvarImmunityFlag.AddChangeHook(OnCvarChanged);
  
  CacheConVars();
  
  LoadTranslations("afk_kick.phrases");
}

public void OnCvarChanged(ConVar cvar, const char[] oldvalue, const char[] newvalue) {
  CacheConVars();
}

void CacheConVars() {
  g_iKickTime = g_hCvarKickTime.IntValue;
  g_iWarnTime = g_hCvarWarnTime.IntValue;
  g_iMinPlayers = g_hCvarMinPlayers.IntValue;
  g_hCvarPrefix.GetString(g_sPrefix, sizeof(g_sPrefix));
  g_hCvarImmunityFlag.GetString(g_sImmunityFlag, sizeof(g_sImmunityFlag));
}

public void OnClientDisconnect(int client) {
  StopKickTimer(client);
}

public void AFKM_OnClientStartAFK(int client) {
  if (!g_hCvarEnabled.BoolValue || g_iKickTime <= 0) {
    return;
  }
  
  StartKickTimer(client);
}

public void AFKM_OnClientEndAFK(int client) {
  StopKickTimer(client);
}

void StartKickTimer(int client) {
  StopKickTimer(client);
  g_hKickTimer[client] = CreateTimer(1.0, Timer_KickCheck, GetClientUserId(client), TIMER_REPEAT);
}

void StopKickTimer(int client) {
  g_hKickTimer[client] = null;
}

Action Timer_KickCheck(Handle timer, int userid) {
  int client = GetClientOfUserId(userid);
  if (client == 0) {
    return Plugin_Stop;
  }
  
  if (g_hKickTimer[client] != timer) {
    return Plugin_Stop;
  }
  
  if (!g_hCvarEnabled.BoolValue || g_iKickTime <= 0) {
    g_hKickTimer[client] = null;
    return Plugin_Stop;
  }
  
  if (!AFKM_IsClientAFK(client)) {
    g_hKickTimer[client] = null;
    return Plugin_Stop;
  }
  
  AFKImmunity immunity = AFKM_GetClientImmunity(client);
  if (immunity >= AFKImmunity_Kick) {
    return Plugin_Continue;
  }
  
  if (HasKickImmunityFlag(client)) {
    return Plugin_Continue;
  }
  
  if (GetClientCount() < g_iMinPlayers) {
    return Plugin_Continue;
  }
  
  int afkTime = AFKM_GetClientAFKTime(client);
  if (afkTime < 0) {
    return Plugin_Continue;
  }
  
  int timeLeft = g_iKickTime - afkTime;
  
  if (timeLeft <= 0) {
    KickClient(client, "[%s] %t", g_sPrefix, "Kick_Message");
    g_hKickTimer[client] = null;
    return Plugin_Stop;
  }
  
  if (timeLeft <= g_iWarnTime && afkTime % WARN_INTERVAL == 0) {
    PrintToChat(client, "[%s] %t", g_sPrefix, "Kick_Warning", timeLeft);
  }
  
  return Plugin_Continue;
}

bool HasKickImmunityFlag(int client) {
  if (g_sImmunityFlag[0] == '\0') {
    return false;
  }
  int iUserFlagBits = GetUserFlagBits(client);
  return (iUserFlagBits & (ReadFlagString(g_sImmunityFlag) | ADMFLAG_ROOT)) > 0;
}
