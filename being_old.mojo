from being_components import (
    PlateMailPiece,
    Shield,
    Sword,
    StrengthRing,
    Armor,
    AttackContributor,
)


@value
struct BeingComponents:
    # TODO: Use metaprogramming to hand in these types and make these lists
    var plate_mail_pieces: List[PlateMailPiece]
    var shields: List[Shield]
    var swords: List[Sword]
    var strength_rings: List[StrengthRing]

    fn __init__(inout self):
        self.plate_mail_pieces = List[PlateMailPiece]()
        self.shields = List[Shield]()
        self.swords = List[Sword]()
        self.strength_rings = List[StrengthRing]()

    # Runs given function for every component that conforms to Armor.
    # TODO: Use metaprogramming to combine this and each_attack_contributor
    fn each_armor[
        func: fn[A: Armor] (a: Pointer[A, _]) capturing -> None
    ](self):
        for x in self.plate_mail_pieces:
            func(x)
        for x in self.shields:
            func(x)

    # Runs given function for every component that conforms to AttackContributor.
    fn each_attack_contributor[
        func: fn[A: AttackContributor] (a: Pointer[A, _]) capturing -> None
    ](self):
        for x in self.swords:
            func(x)
        for x in self.strength_rings:
            func(x)


@value
struct Being(CollectionElement):
    var symbol: String
    var hp: Int
    var energy: Int
    var strength: Int
    var components: BeingComponents

    fn calculate_attack_power(self) -> Int:
        total_attack_power = self.strength

        @parameter
        fn iterate_attack_contributor[A: AttackContributor](a: Pointer[A, _]):
            total_attack_power += a[].contribute_attack_power()

        self.components.each_attack_contributor[iterate_attack_contributor]()
        return total_attack_power

    fn calculate_defense(self) -> Int:
        total_defense = 0

        @parameter
        fn iterate_defense[A: Armor](a: Pointer[A, _]):
            total_defense += a[].contribute_defense()

        self.components.each_armor[iterate_defense]()
        return total_defense

    # These are immutable, and we return a new instance,
    # so we could probably assume whatever we want about
    # their groups.
    fn calculate_attack_cost(self, other: Being) -> Int:
        return 200 + max(0, self.strength - other.calculate_defense())

    fn calculate_defend_cost(self, other: Being) -> Int:
        return 100 + max(0, self.calculate_defense() - other.strength)
