#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "No Team Flash",
    author = "Ilusion9",
    description = "Alive teammates cannot be flashed",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

#define NO_FLASH_DURATION	0.0
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
	
	// Anti flash alive teammates
	int teamThrower = GetClientTeam(thrower);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_FlashDuration[i] = NO_FLASH_DURATION;
		if (i == thrower || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != teamThrower)
		{
			continue;
		}
		
		g_FlashDuration[i] = GetClientFlashDuration(i);
	}
	
	// The spectators will see exactly what the player that they are spectating sees
	for (int i = 1; i <= MaxClients; i++)
	{		
		if (!IsClientInGame(i) || !IsClientObserver(i))
		{
			continue;
		}
		
		int specTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		if (specTarget == -1)
		{
			continue;
		}
		
		g_FlashDuration[i] = g_FlashDuration[specTarget];
	}
	
	RequestFrame(SetNewFlashDurations);
}

void SetNewFlashDurations(any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || g_FlashDuration[i] == NO_FLASH_DURATION)
		{
			continue;
		}
		
		SetClientFlashDuration(i, g_FlashDuration[i]);
	}
}

float GetClientFlashDuration(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFlashDuration")
}

void SetClientFlashDuration(int client, float duration)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration);
}
