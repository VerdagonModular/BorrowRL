# TODO:
# - Added (CollectionElement), then lucky I knew to add @value to satisfy those errors
# - for i, entry in list: doesn't work. even adding enumerate didnt either?
# - when I tried to make Terrain's init take a fn, like this:
#   fn __init__[
#       make_tile: fn (row_i: Int, col_i: Int) capturing -> Tile
#   ](inout self, num_rows: Int, num_cols: Int):
#   I couldn't use it:
#   ...: error: 'Terrain' expects 0 parameters, but 1 was specified
#   terrain = Terrain[make_tile](80, 18)
#   Had to make it an argument, and "escaping".
# - Why did I have to import Dict but not List?
# - Would have been nice to have something derive eq, ne, hash for me
# - fn __getitem__(self, loc: Loc) raises -> ref [self.tiles] Tile:
#   didn't work:
#   error: cannot use a dynamic value in lifetime specifier
#       fn __getitem__(self, loc: Loc) raises -> ref [self.tiles] Tile:
#                                                     ~~~~^~~~~~


from collections import Dict, KeyElement

@value
struct Being(CollectionElement):
    var symbol: String
    var hp: Int
    var energy: Int
    var armor: Int
    var strength: Int

    fn calculate_attack_power(self) -> Int:
        return self.strength

    fn calculate_attack_cost(self, other: Being) -> Int:
        return 200 + max(0, self.strength - other.armor)

    fn calculate_defend_cost(self, other: Being) -> Int:
        return 100 + max(0, self.armor - other.strength)

    fn calculate_defense(self) -> Int:
        return self.armor


@value
struct GenId[T: AnyType]:
    var index: Int
    # Never zero.
    var gen: Int


@value
struct GenListEntry[T: CollectionElement](CollectionElement):
    var gen: Int
    var value: T


struct GenList[T: CollectionElement]:
    var list: List[GenListEntry[T]]

    fn __init__(inout self):
        self.list = List[GenListEntry[T]]()

    fn __getitem__(self, ind: GenId[T]) raises -> T:
        entry_ref = self.list[ind.index]
        if entry_ref.gen != ind.gen:
            raise "wat"
        return entry_ref.value

    fn insert(inout self, owned value: T) -> GenId[T]:
        # TODO(optimize): Keep a free-list of vacant indices, instead
        # of searching through it like this.
        list_end = len(self.list)
        for i in range(0, list_end):
            entry = self.list[i]
            if entry.gen < 0:
                entry.gen = -entry.gen + 1
                entry.value = value^
                return GenId[T](i, entry.gen)
        # If we get here, there were no empty entries, so let's add one.
        new_entry_gen = 1
        self.list.append(GenListEntry[T](new_entry_gen, value^))
        return GenId[T](list_end, new_entry_gen)



fn attack(
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

fn attack_new(
    inout a: Being,
    inout d: Being,
) raises:
  d.energy -= d.calculate_defend_cost(a)
  d.hp -= a.calculate_attack_power() - d.calculate_defense()
  a.energy -= a.calculate_attack_cost(d)


@value
struct Tile(CollectionElement):
    var symbol: String


@value
struct Loc(KeyElement):
    var row: Int
    var col: Int

    @always_inline("nodebug")
    fn __hash__(self) -> UInt:
        return int(self.row) + 1333337 * self.col

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        return self.row == other.row and self.col == other.col

    @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)



struct Terrain:
    var num_rows: Int
    var num_cols: Int
    var tiles: List[Tile]

    fn __init__(inout self, num_rows: Int, num_cols: Int, make_tile: fn (row_i: Int, col_i: Int) escaping -> Tile):
        self.num_rows = num_rows
        self.num_cols = num_cols
        self.tiles = List[Tile](capacity=num_rows * num_cols)
        for row_i in range(0, num_rows):
            for col_i in range(0, num_cols):
                self.tiles.append(make_tile(row_i, col_i))

    fn __getitem__(self, loc: Loc) raises -> Tile:
        return self.tiles[loc.row * self.num_cols + loc.col]
    # fn __getitem__(self, loc: Loc) raises -> ref [self.tiles[0]] Tile:
    #     return self.tiles[loc.row * self.num_cols + loc.col]


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

    attack(beings, player_id, enemy_id)

    # attack_new(beings[player_id], beings[enemy_id])
    # TODO: This doesn't illustrate what we think it does, because
    # these are just copies, lol. Change __getitem__ to return a ref!
    var b_1: Being = beings[player_id]
    var b_2: Being = beings[enemy_id]
    attack_new(b_1, b_2)

    display(terrain, beings, loc_to_being_map)