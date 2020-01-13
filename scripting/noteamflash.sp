#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo =
{
    name = "No Team Flash",
    author = "Ilusion9",
    description = "Players will not be flashed by teammates",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

int g_ThrowerId;
int g_ThrowerTeam;
float g_FlashDuration[MAXPLAYERS + 1];

ConVar g_Cvar_NoTeamFlash;
ConVar g_Cvar_MessageTeamFlash;

public void OnPluginStart()
{
	LoadTranslations("noteamflash.phrases");
	
	g_Cvar_NoTeamFlash = CreateConVar("sm_no_team_flash", "1", "Determine whether players should be protected by flashes done by teammates or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_MessageTeamFlash = CreateConVar("sm_team_flash_message", "1", "Determine whether players should be announced when teammates blinds them or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	AutoExecConfig(true, "noteamflash");
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
			if (g_Cvar_NoTeamFlash.BoolValue)
			{
				if (CheckCommandAccess(client, "NoTeamFlash", 0, false))
				{
					SetClientFlashDuration(client, g_FlashDuration[client]);
				}
			}
			
			if (g_Cvar_MessageTeamFlash.BoolValue)
			{
				char clientName[MAX_NAME_LENGTH];
				char throwerName[MAX_NAME_LENGTH] = "[disconnected]";
				
				int thrower = GetClientOfUserId(g_ThrowerId);
				if (thrower)
				{
					GetClientName(thrower, throwerName, sizeof(throwerName));
					GetClientName(client, clientName, sizeof(clientName));
					PrintToChat(thrower, " \x04[Team Flash]\x01 %t", "Flashed a Teammate", clientName);
				}
				
				PrintToChat(client, " \x04[Team Flash]\x01 %t", "Flashed by Teammate", throwerName);
			}
		}
	}
	else
	{
		if (IsClientObserver(client))
		{
			/* First person mode */
			if (GetClientObserverMode(client) != 4)
			{
				return;
			}
			
			int specTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (specTarget < 1 || specTarget > MaxClients)
			{
				return;
			}
			
			if (g_Cvar_NoTeamFlash.BoolValue)
			{
				SetClientFlashDuration(client, g_FlashDuration[specTarget]);
			}
			
			if (g_Cvar_MessageTeamFlash.BoolValue)
			{
				char targetName[MAX_NAME_LENGTH];
				char throwerName[MAX_NAME_LENGTH] = "[disconnected]";
				
				int thrower = GetClientOfUserId(g_ThrowerId);
				if (thrower)
				{
					GetClientName(thrower, throwerName, sizeof(throwerName));
				}
				
				GetClientName(specTarget, targetName, sizeof(targetName));
				PrintToChat(client, " \x04[Team Flash]\x01 %t", "Target Flashed by Teammate", targetName, throwerName);
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

int GetClientObserverMode(int client)
{
	return GetEntProp(client, Prop_Send, "m_iObserverMode");
}

float GetClientFlashDuration(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
}

void SetClientFlashDuration(int client, float duration)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration);
}
