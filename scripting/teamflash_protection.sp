#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Flash Protection",
    author = "Ilusion9",
    description = "Players will not be flashed by their teammates",
    version = "1.1",
    url = "https://github.com/Ilusion9/"
};

enum struct ThrowerInfo
{
	int Id;
	int Team;
}

ThrowerInfo g_Thrower;
float g_FlashExpireTime[MAXPLAYERS + 1];

StringMap g_Map_FlashThrowerTeam;
ConVar g_Cvar_FlashProtection;

public void OnPluginStart()
{
	g_Map_FlashThrowerTeam = new StringMap();
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	g_Cvar_FlashProtection = CreateConVar("sm_teamflash_protection", "1", "Protect players against flashes made by their teammates?", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "teamflash_protection");
}

public void OnMapStart()
{
	g_Map_FlashThrowerTeam.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "flashbang_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_OnFlashbangProjectileSpawn_Post);
	}
}

public void SDK_OnFlashbangProjectileSpawn_Post(int entity)
{
	RequestFrame(Frame_FlashbangProjectileSpawn, EntIndexToEntRef(entity));
}

public void Frame_FlashbangProjectileSpawn(any data)
{
	int entity = EntRefToEntIndex(view_as<int>(data));
	if (entity == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");	
	if (thrower < 1 || thrower > MaxClients || !IsClientInGame(thrower))
	{
		return;
	}
	
	char key[64];
	IntToString(entity, key, sizeof(key));
	g_Map_FlashThrowerTeam.SetValue(key, GetClientTeam(thrower));
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	float gameTime = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_FlashExpireTime[i] = gameTime + GetClientFlashDuration(i);
		}
	}
	
	g_Thrower.Id = event.GetInt("userid");
	
	char key[64];
	int entity = event.GetInt("entityid");
	IntToString(entity, key, sizeof(key));
	
	if (!g_Map_FlashThrowerTeam.GetValue(key, g_Thrower.Team))
	{
		g_Thrower.Team = CS_TEAM_NONE;
	}
	
	g_Map_FlashThrowerTeam.Remove(key);
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Cvar_FlashProtection.BoolValue || g_Thrower.Team == CS_TEAM_NONE)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	if (g_Thrower.Id == userId)
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
		if (GetClientTeam(client) == g_Thrower.Team)
		{
			if (CheckCommandAccess(client, "TeamFlashProtection", 0, false))
			{
				float newFlashDuration = g_FlashExpireTime[client] - GetGameTime();
				SetClientFlashDuration(client, newFlashDuration > 0.0 ? newFlashDuration : 0.0);
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
			if (specTarget < 1 || specTarget > MaxClients || !IsClientInGame(specTarget))
			{
				return;
			}
			
			if (GetClientTeam(specTarget) != g_Thrower.Team)
			{
				return;
			}
			
			float newFlashDuration = g_FlashExpireTime[specTarget] - GetGameTime();
			SetClientFlashDuration(client, newFlashDuration > 0.0 ? newFlashDuration : 0.0);
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
