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
};
