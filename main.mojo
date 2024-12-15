from collections import Dict, KeyElement
from gen_list import GenList, GenId
from terrain import Terrain, Tile, Loc

trait Armor:
    fn contribute_defense(self) -> Int:
        ...

@value
struct PlateMailPiece(Armor):
    var a: Int # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")
    fn contribute_defense(self) -> Int:
        return 5

@value
struct Shield(Armor):
    var a: Int # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")
    fn contribute_defense(self) -> Int:
        return 20

trait AttackContributor:
    fn contribute_attack_power(self) -> Int:
        ...

@value
struct StrengthRing(AttackContributor):
    var a: Int # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")
    fn contribute_attack_power(self) -> Int:
            return 40

@value
struct Sword(AttackContributor):
    var a: Int # Without this, can't instantiate a Pointer to it, ("constraint failed: size must be greater than zero")
    fn contribute_attack_power(self) -> Int:
            return 20


@value
struct BeingComponents:
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
    fn each_armor[
        func: fn[A: Armor](a: Pointer[A, _]) capturing -> None
    ](self):
        for x in self.plate_mail_pieces:
            func(x)
        for x in self.shields:
            func(x)

    # Runs given function for every component that conforms to AttackContributor.
    fn each_attack_contributor[
        func: fn[A: AttackContributor](a: Pointer[A, _]) capturing -> None
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


# Using Nick's proposal, would be something like:
# fn attack_new[g: Group](
#     inout a: ref[g] Being,
#     inout d: ref[g] Being
# ) raises:
fn attack_new(
    inout a: Being,
    inout d: Being
) raises:
    d.energy -= d.calculate_defend_cost(a)
    d.hp -= a.calculate_attack_power() - d.calculate_defense()
    a.energy -= a.calculate_attack_cost(d)


# Like above, but using conservative Rust-style borrowing.
fn attack_old(
    inout beings: GenList[Being],
    attacker_id: GenId[Being],
    defender_id: GenId[Being],
) raises:
    var a = beings[attacker_id]
    var d = beings[defender_id]
    var a_power = a.calculate_attack_power()
    var a_energy_cost = a.calculate_attack_cost(d)
    var d_armor = d.calculate_defense()
    var d_energy_cost = d.calculate_defend_cost(a)

    var d_mut = beings[defender_id]
    d_mut.energy -= d_energy_cost
    d_mut.hp -= a_power - d_armor

    var a_mut = beings[attacker_id]
    a_mut.energy -= a_energy_cost


fn display(
    terrain: Terrain,
    beings: GenList[Being],
    loc_to_being_map: Dict[Loc, GenId[Being]]
) raises:
    for row_i in range(0, terrain.num_rows):
        for col_i in range(0, terrain.num_cols):
            loc = Loc(row_i, col_i)
            if loc in loc_to_being_map:
                being_id = loc_to_being_map[loc]
                being = beings[being_id]
                print(being.symbol, end="")
            else:
                print(terrain[loc].symbol, end="")
        print("")



fn main() raises:
    num_rows = 18
    num_cols = 80

    loc_to_being_map = Dict[Loc, GenId[Being]]()

    # TODO: Make this into a lambda or something
    fn make_tile(row_i: Int, col_i: Int) -> Tile:
        symbol = "."
        if row_i == 0 or row_i == num_rows - 1 or
            col_i == 0 or col_i == num_cols - 1:
            symbol = "#"
        return Tile(symbol)
    terrain = Terrain(num_rows, num_cols, make_tile)
    # TODO: Make Mojo able to do this epic piece of sorcery:
    # terrain = Terrain(80, 18) lambda(row_i, col_i):
    #     symbol = "."
    #     if row_i == 0 or row_i == num_rows - 1 or
    #         col_i == 0 or col_i == num_cols - 1:
    #         symbol = "#"
    #     return Tile(symbol)

    beings = GenList[Being]()
    player_id = beings.insert(Being("@", 30, 0, 1, BeingComponents()))
    loc_to_being_map[Loc(5, 20)] = player_id
    enemy_id = beings.insert(Being("g", 10, 0, 0, BeingComponents()))
    loc_to_being_map[Loc(15, 15)] = enemy_id

    attack_old(beings, player_id, enemy_id)

    # attack_new(beings[player_id], beings[enemy_id])
    # TODO: This doesn't illustrate what we think it does, because
    # these are just copies, lol. Change __getitem__ to return a ref!
    var b_1: Being = beings[player_id]
    var b_2: Being = beings[enemy_id]
    attack_new(b_1, b_2)

    display(terrain, beings, loc_to_being_map)