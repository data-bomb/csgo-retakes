#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <retakes>

Handle gH_Cvar_Overlay_B = INVALID_HANDLE;
Handle gH_Cvar_Overlay_A = INVALID_HANDLE;
Handle gH_Cvar_FreezeTime = INVALID_HANDLE;

float gShadow_FreezeTime;
char gShadow_Overlay_A[PLATFORM_MAX_PATH];
char gShadow_Overlay_B[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "CS:GO Retakes: Site Announcements",
	author = "databomb",
	description = "Provides CTs HUD on Bomb Site",
	version = "1.0.0",
	url = "https://github.com/splewis/csgo-retakes"
};

public OnPluginStart()
{
	gH_Cvar_Overlay_A = CreateConVar("sm_retakes_overlay_a", "overlays/retakes/a1", "Retakes A Overlay", 0);
	Format(gShadow_Overlay_A, PLATFORM_MAX_PATH, "overlays/retakes/a1");
	
	gH_Cvar_Overlay_B = CreateConVar("sm_retakes_overlay_b", "overlays/retakes/b", "Retakes B Overlay", 0);
	Format(gShadow_Overlay_B, PLATFORM_MAX_PATH, "overlays/retakes/b");
	
	HookConVarChange(gH_Cvar_Overlay_A, TeamOverlay_CvarChanged);
	HookConVarChange(gH_Cvar_Overlay_B, TeamOverlay_CvarChanged);
	
	HookEvent("round_poststart", RetakesOverlays_RoundPostStart);
	HookEvent("round_end", RetakesOverlays_RoundEnd);
}

public OnConfigsExecuted()
{
	GetConVarString(gH_Cvar_Overlay_A, gShadow_Overlay_A, sizeof(gShadow_Overlay_A));
	GetConVarString(gH_Cvar_Overlay_B, gShadow_Overlay_B, sizeof(gShadow_Overlay_B));
	gH_Cvar_FreezeTime = FindConVar("mp_freezetime");
	if (gH_Cvar_FreezeTime != INVALID_HANDLE)
	{
		gShadow_FreezeTime = GetConVarFloat(gH_Cvar_FreezeTime);
	}
}

public Action RetakesOverlays_RoundPostStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (!Retakes_Live())
	{
		return;
    }
	Bombsite bombsite = Retakes_GetCurrrentBombsite();
	
	if (!Retakes_InEditMode())
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
			{
				if (GetClientTeam(client) == CS_TEAM_CT)
				{
					if (bombsite == BombsiteA)
					{
						ShowOverlayToClient(client, gShadow_Overlay_A);
					}
					else
					{
						ShowOverlayToClient(client, gShadow_Overlay_B);
					}
				}
			}
		}
		
		if (gH_Cvar_FreezeTime != INVALID_HANDLE)
		{
			CreateTimer(gShadow_FreezeTime, Timer_ClearOverlay);
		}
		else
		{
			CreateTimer(5.7, Timer_ClearOverlay);
		}
	}
}

public Action Timer_ClearOverlay(Handle timer)
{
	ShowOverlayToAll("");
	return Plugin_Stop;
}

public TeamOverlay_CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == gH_Cvar_Overlay_A)
	{
		Format(gShadow_Overlay_A, PLATFORM_MAX_PATH, newValue);
		if (strlen(gShadow_Overlay_A) > 0)
		{
			CacheMaterial(gShadow_Overlay_A);
		}
	}
	else if (cvar == gH_Cvar_Overlay_B)
	{
		Format(gShadow_Overlay_B, PLATFORM_MAX_PATH, newValue);
		if (strlen(gShadow_Overlay_B) > 0)
		{
			CacheMaterial(gShadow_Overlay_B);
		}
	}
	else if (cvar == gH_Cvar_FreezeTime)
	{
		gShadow_FreezeTime = GetConVarFloat(gH_Cvar_FreezeTime);
	}
}

public OnMapStart()
{
	if (strlen(gShadow_Overlay_A) > 0)
	{
		CacheMaterial(gShadow_Overlay_A);
	}
	if (strlen(gShadow_Overlay_B) > 0)
	{
		CacheMaterial(gShadow_Overlay_B);
	}
}

public RetakesOverlays_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ShowOverlayToAll("");
}

stock CacheMaterial(const String:path[])
{
	// Add VMT
	char sVMT[PLATFORM_MAX_PATH];
	Format(sVMT, PLATFORM_MAX_PATH, "%s.vmt", path);
	PrecacheDecal(sVMT, true);
	
	// Lazily add VTF
	char sVTF[PLATFORM_MAX_PATH];
	Format(sVTF, PLATFORM_MAX_PATH, "%s.vtf", path);
	PrecacheDecal(sVTF, true);

	char sDownloadPath[PLATFORM_MAX_PATH];
	Format(sDownloadPath, PLATFORM_MAX_PATH, "materials/%s", sVTF);
	AddFileToDownloadsTable(sDownloadPath);
	Format(sDownloadPath, PLATFORM_MAX_PATH, "materials/%s", sVMT);
	AddFileToDownloadsTable(sDownloadPath);
}

stock ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

stock ShowOverlayToAll(const String:overlaypath[])
{
	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			ShowOverlayToClient(x, overlaypath);
		}
	}
}
