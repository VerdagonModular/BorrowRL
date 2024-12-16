from collections import Dict, KeyElement
from gen_list import GenList, GenId
from terrain import Terrain, Tile, Loc

@value
struct Being(CollectionElement):
    var symbol: String
    var hp: Int
    var energy: Int
    var armor: Int
    var strength: Int

    fn calculate_attack_power(self) -> Int:
        return self.strength

    # These are immutable, and we return a new instance,
    # so we could probably assume whatever we want about
    # their groups.
    fn calculate_attack_cost(self, other: Being) -> Int:
        return 200 + max(0, self.strength - other.armor)

    fn calculate_defend_cost(self, other: Being) -> Int:
        return 100 + max(0, self.armor - other.strength)

    fn calculate_defense(self) -> Int:
        return self.armor


# Using Nick's proposal, would be something like:
# fn attack_new[g: MutableGroup](
#     a: ref[g] Being,
#     d: ref[g] Being
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
    player_id = beings.insert(Being("@", 30, 0, 1, 2))
    loc_to_being_map[Loc(5, 20)] = player_id
    enemy_id = beings.insert(Being("g", 10, 0, 0, 3))
    loc_to_being_map[Loc(15, 15)] = enemy_id

    attack_old(beings, player_id, enemy_id)

    # attack_new(beings[player_id], beings[enemy_id])
    # TODO: This doesn't illustrate what we think it does, because
    # these are just copies, lol. Change __getitem__ to return a ref!
    var b_1: Being = beings[player_id]
    var b_2: Being = beings[enemy_id]
    attack_new(b_1, b_2)

    display(terrain, beings, loc_to_being_map)