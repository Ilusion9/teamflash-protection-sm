#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
    name = "Team Flash Manager",
    author = "Ilusion9",
    description = "Team flash manager for CS:GO",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

int g_ThrowerId;
int g_ThrowerTeam;
float g_FlashDuration[MAXPLAYERS + 1];

ConVar g_Cvar_NoFlash;
ConVar g_Cvar_NoSpecFlash;
ConVar g_Cvar_FlashMessage;

public void OnPluginStart()
{
	LoadTranslations("teamflashmanager.phrases");
	
	g_Cvar_NoFlash = CreateConVar("sm_no_team_flash", "1", "If set, teammates cannot be flashed.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_NoSpecFlash = CreateConVar("sm_no_spec_flash", "1", "If set, spectators cannot be flashed if the target is teamflashed.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_FlashMessage = CreateConVar("sm_team_flash_message", "1", "Notify players when a teammate flashed them?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	AutoExecConfig(true, "teamflashmanager");
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	g_ThrowerId = event.GetInt("userid");
	int client = GetClientOfUserId(g_ThrowerId);
	
	if (!client || !IsClientInGame(client))
	{
		g_ThrowerTeam = CS_TEAM_NONE;
		return;
	}
	
	g_ThrowerTeam = GetClientTeam(client);
	GetFlashDurations();
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (g_ThrowerTeam == CS_TEAM_NONE)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	if (g_ThrowerId == userId)
	{
		return;
	}
	
	int client = GetClientOfUserId(userId);
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	if (IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == g_ThrowerTeam)
		{
			if (g_Cvar_FlashMessage.BoolValue)
			{
				char throwerName[MAX_NAME_LENGTH];
				int thrower = GetClientOfUserId(g_ThrowerId);
				
				if (thrower)
				{
					GetClientName(thrower, throwerName, sizeof(throwerName));
					Format(throwerName, sizeof(throwerName), "\x04%s\x01", throwerName);
					PrintToChat(client, "[SM] %t", "Team Flashed", throwerName);
				}
				else
				{
					PrintToChat(client, "[SM] %t", "Team Flashed", "\x07[disconnected]\x01");
				}
			}
			
			if (g_Cvar_NoFlash.BoolValue)
			{
				SetClientFlashDuration(client, g_FlashDuration[client]);
			}
		}
	}
	else
	{
		if (g_Cvar_NoFlash.BoolValue && g_Cvar_NoSpecFlash.BoolValue)
		{
			if (IsClientObserver(client))
			{
				int specTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (specTarget < 1 || specTarget > MaxClients)
				{
					return;
				}
				
				SetClientFlashDuration(client, g_FlashDuration[specTarget]);
			}
		}
	}
}

void GetFlashDurations()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_FlashDuration[i] = GetClientFlashDuration(i);
		}
	}
}

float GetClientFlashDuration(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
}

void SetClientFlashDuration(int client, float duration)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration);
}
