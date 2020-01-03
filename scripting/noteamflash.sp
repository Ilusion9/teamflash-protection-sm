#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "No Team Flash",
    author = "Ilusion9",
    description = "Teammates cannot be flashed",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

bool g_SetFlashDuration[MAXPLAYERS + 1];
float g_FlashDuration[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	int thrower = GetClientOfUserId(event.GetInt("userid"));
	if (!thrower || !IsClientInGame(thrower))
	{
		return;
	}
	
	// Get teammates flash durations and keep them further
	int teamThrower = GetClientTeam(thrower);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_SetFlashDuration[i] = false;
		if (i == thrower || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != teamThrower)
		{
			continue;
		}
		
		g_SetFlashDuration[i] = true;
		g_FlashDuration[i] = GetClientFlashDuration(i);
	}
	
	// Spectators will see exactly what the target sees
	for (int i = 1; i <= MaxClients; i++)
	{		
		if (!IsClientInGame(i) || !IsClientObserver(i))
		{
			continue;
		}
		
		int specTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		if (specTarget < 1 || specTarget > MaxClients)
		{
			continue;
		}
		
		g_FlashDuration[i] = g_FlashDuration[specTarget];
	}
	
	RequestFrame(SetFlashDurations);
}

void SetFlashDurations(any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !g_SetFlashDuration[i])
		{
			continue;
		}
		
		SetClientFlashDuration(i, g_FlashDuration[i]);
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
