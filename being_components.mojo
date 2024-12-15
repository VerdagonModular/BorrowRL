trait Armor:
    fn contribute_defense(self) -> Int:
        ...


@value
struct PlateMailPiece(Armor):
    var a: Int  # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")

    fn contribute_defense(self) -> Int:
        return 5


@value
struct Shield(Armor):
    var a: Int  # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")

    fn contribute_defense(self) -> Int:
        return 20


trait AttackContributor:
    fn contribute_attack_power(self) -> Int:
        ...


@value
struct StrengthRing(AttackContributor):
    var a: Int  # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")

    fn contribute_attack_power(self) -> Int:
        return 40


@value
struct Sword(AttackContributor):
    var a: Int  # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")

    fn contribute_attack_power(self) -> Int:
        return 20
