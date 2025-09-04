pub const ItemTypeEnum = enum {
    None,
    GunImprovement,
    Shield,
};
pub const ItemGunImprovement = struct {
    gunSpeedIncrease: f32 = 1.0,
};
pub const ItemShield = struct {
    shieldDuration: f32 = 4.0,
};

pub const ItemTypeUnion = union(enum) {
    GunImprovement: ItemGunImprovement,
    Shield: ItemShield,
};

pub const Item = struct {
    type: ItemTypeUnion = undefined,
};
