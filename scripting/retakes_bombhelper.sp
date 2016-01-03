#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <retakes>

bool gBombPlanted = false;
int gBombCarrier = 0;

public Plugin:myinfo =
{
	name = "CS:GO Retakes: Bomb Plant Helpers",
	author = "databomb",
	description = "Provides Bomb Planter Feedback",
	version = "1.0.0",
	url = "https://github.com/splewis/csgo-retakes"
};

public OnPluginStart()
{
	HookEvent("exit_bombzone", Event_ExitBombZone);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("round_prestart", Event_PreStart);
	HookEvent("bomb_pickup", Event_BombPickup);
	
	// Account for late loading
	for (new idx = 1; idx <= MaxClients ; idx++)
	{
		if (IsClientInGame(idx))
		{
			SDKHook(idx, SDKHook_WeaponCanSwitchTo, CanSwitchTo);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchTo, CanSwitchTo); 
}

public Action CanSwitchTo(int client, int weapon)
{
	if (!gBombPlanted && Retakes_Live())
	{
		if (client == gBombCarrier)
		{
			IsValidEntity(weapon)
			{
				char weaponName[48];
				GetEntityClassname(weapon, weaponName, sizeof(weaponName));
				
				// if the weapon is NOT the C4
				if (strcmp(weaponName, "weapon_c4"))
				{
					PrintHintText(client, "First you must plant the bomb!");
					return Plugin_Handled;
				}
			}
		}	
	}
	return Plugin_Continue;
}

public Action Event_BombPickup(Handle event, const char[] name, bool dontBroadcast)
{
	gBombCarrier = GetClientOfUserId(GetEventInt(event, "userid"));
}

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast)
{
	gBombPlanted = true;
	gBombCarrier = 0;
}

public Action Event_PreStart(Handle event, const char[] name, bool dontBroadcast)
{
	gBombPlanted = false;
}

public OnMapStart()
{
	gBombPlanted = false;
}

public Action Event_ExitBombZone(Handle event, const char[] name, bool dontBroadcast)
{
	if (!Retakes_Live())
	{
		return;
    }
	bool hasbomb = GetEventBool(event, "hasbomb");
	bool isplanted = GetEventBool(event, "isplanted");
	
	// Only proceed if the player has the bomb and the bomb isn't planted
	if (!hasbomb || isplanted || Retakes_InEditMode())
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	new duration = 100;
	new holdtime = 50;
	new flags = 0x0002;
	new color[4] = { 0, 0, 0, 128 };
	color[0] = 255;
	color[1] = 20;
	color[2] = 28;
 
	new Handle:message = StartMessageOne("Fade", client, 0);
 
	if (GetUserMessageType() == UM_Protobuf) //protobuf
	{
		PbSetInt(message, "duration", duration);
		PbSetInt(message, "hold_time", holdtime);
		PbSetInt(message, "flags", flags);
		PbSetColor(message, "clr", color);
	}
	else //regular msg
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
 
	EndMessage(); 
	
	PrintHintText(client, "You have the bomb!");
}
