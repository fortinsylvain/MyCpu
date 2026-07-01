using System.Collections.Generic;

public enum VarType
{
    U8 = 1,
    U16 = 2,
    U32 = 4
}

public class SymbolTable
{
    private struct Entry { public int Offset; public VarType Type; }

    private Dictionary<string, Entry> map = new();
    private int nextOffset = 0; // measured in bytes

    // Get existing offset or allocate with a default type (U32) if missing
    public int GetOrAdd(string name)
    {
        return GetOrAdd(name, VarType.U32);
    }

    // Allocate a symbol with an explicit type (aligned)
    public int GetOrAdd(string name, VarType type)
    {
        if (map.ContainsKey(name))
            return map[name].Offset;

        // align nextOffset based on type
        int align = (int)type;
        if (nextOffset % align != 0)
            nextOffset += align - (nextOffset % align);

        int off = nextOffset;
        map[name] = new Entry { Offset = off, Type = type };
        nextOffset += (int)type;
        return off;
    }

    public VarType GetType(string name)
    {
        if (map.ContainsKey(name))
            return map[name].Type;
        return VarType.U32;
    }

    public void SetType(string name, VarType type)
    {
        if (map.ContainsKey(name))
        {
            var e = map[name];
            e.Type = type;
            map[name] = e;
            return;
        }
        GetOrAdd(name, type);
    }

    public int Count => nextOffset;

    public IEnumerable<KeyValuePair<string,int>> GetAll()
    {
        foreach (var kv in map)
            yield return new KeyValuePair<string,int>(kv.Key, kv.Value.Offset);
    }
}