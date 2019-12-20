#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "Anti Team Flash",
    author = "Ilusion9",
    description = "Anti flash alive teammates",
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
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	GetFlashDurations(client);
	RequestFrame(SetFlashDurations);
}

void GetFlashDurations(int thrower)
{
	int teamThrower = GetClientTeam(thrower);
	
	// Anti flash alive teammates
	for (int i = 1; i <= MaxClients; i++)
	{
		g_FlashDuration[i] = NO_FLASH_DURATION;
		if (i == thrower || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != teamThrower)
		{
			continue;
		}
		
		g_FlashDuration[i] = GetEntPropFloat(i, Prop_Send, "m_flFlashDuration");
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
}

void SetFlashDurations(any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || g_FlashDuration[i] == NO_FLASH_DURATION)
		{
			continue;
		}
		
		SetEntPropFloat(i, Prop_Send, "m_flFlashDuration", g_FlashDuration[i]);
	}
}