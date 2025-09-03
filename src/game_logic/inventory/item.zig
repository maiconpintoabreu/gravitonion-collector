pub const ItemTypeEnum = enum {
    None,
    GunPower,
    Shield,
};
pub const ItemGunImprovement = struct {
    gunSpeedIncrease: f32 = 0.0,
};
pub const ItemSheild = struct {
    shieldDuration: f32 = 0.0,
};

pub const ItemTypeUnion = union(enum) {
    GunPower: ItemGunImprovement,
    Shield: ItemGunImprovement,
};

pub const Item = struct {
    type: ItemTypeUnion = undefined,
};
