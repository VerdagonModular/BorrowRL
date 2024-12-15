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

    fn __init__(
        inout self,
        num_rows: Int,
        num_cols: Int,
        make_tile: fn (row_i: Int, col_i: Int) escaping -> Tile,
    ):
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
