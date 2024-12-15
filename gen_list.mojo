@value
struct GenId[T: AnyType]:
    var index: Int
    var gen: Int  # Never zero


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
