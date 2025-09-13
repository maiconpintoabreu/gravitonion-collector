const rl = @import("raylib");
const ResourceManagerZig = @import("../../resource_manager.zig");

pub const ItemGunImprovement = struct {
    gunSpeedIncrease: f32 = 1.0,
};
pub const ItemShield = struct {
    shieldDuration: f32 = 4.0,
};
pub const ItemAntiGravity = struct {
    antiGravityDuration: f32 = 4.0,
};

pub const ItemTypeUnion = union(enum) {
    GunImprovement: ItemGunImprovement,
    Shield: ItemShield,
    AntiGravity: ItemAntiGravity,
};

pub const Item = struct {
    type: ItemTypeUnion = undefined,
    pub fn getTextureData(self: Item) ResourceManagerZig.TextureData {
        const resourceManager = ResourceManagerZig.resourceManager;
        return switch (self.type) {
            .AntiGravity => resourceManager.powerupGravityData,
            .GunImprovement => resourceManager.powerupGunData,
            .Shield => resourceManager.powerupShieldData,
        };
    }
};
