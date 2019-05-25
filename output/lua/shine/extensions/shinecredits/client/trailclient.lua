local kTrailCinematicNames =
{
    PrecacheAsset("cinematics/alien/drifter/trail1.cinematic"),
    PrecacheAsset("cinematics/alien/drifter/trail2.cinematic"),
    PrecacheAsset("cinematics/alien/drifter/trail3.cinematic"),
}

local kTrailFadeOutCinematicNames =
{
    PrecacheAsset("cinematics/alien/drifter/trail_fadeout.cinematic"),
}

TrailClient = {}

function TrailClient:CreateTrail(client,message)
    if not self.trailCinematic then
        self.trailCinematic = client.CreateTrailCinematic(RenderScene.Zone_Default)
        self.trailCinematic:SetCinematicNames(kTrailCinematicNames)
        self.trailCinematic:SetFadeOutCinematicNames(kTrailFadeOutCinematicNames)
        self.trailCinematic:AttachTo(client.GetLocalPlayer(), TRAIL_ALIGN_MOVE,  Vector(0, 0.3, -0.9))
        self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.trailCinematic:SetOptions( {
            numSegments = 8,
            collidesWithWorld = false,
            visibilityChangeDuration = 1.2,
            fadeOutCinematics = true,
            stretchTrail = false,
            trailLength = 3.5,
            minHardening = 0.1,
            maxHardening = 0.3,
            hardeningModifier = 0,
            trailWeight = 0.0
        } )
    end
end

return TrailClient
