function _hpdemo(state, root, t = 0) {
    const choreography = root.querySelector(":scope script");
    const main = root.querySelector(":scope main");
    const layers = state.layers ?? [...main.children];
    const sss = state.sss ?? parse(choreography.textContent);
    const ss = sss[t = Math.min(Math.max(t, 0), sss.length - 1)];
    const skips = ss.map((s, i) => /[qur]/.test(s));
    const quiets = ss.map((s, i) => /[q]/.test(s));

    const order = ss
        // map each layer state to [index i, state s, order o]
        // 0:[0,"",3], 1:[1,"",6], 2:[2,"",0], 3:[3,"",0], ...
        .map((s, i) => [i, s, getOrder(s)])
        // sort [i,s,o] by order (o), then by index (i)
        // 0:[2,"",0], 1:[3,"",0], 2:[0,"",3], 3:[1,"",6], ...
        .sort(([pi,ps,po],[qi,qs,qo]) => po - qo || pi - qi)
        // append z-index (z) to each, mapping [i,s,o] to [i,s,o,z]
        // 0:[2,"",0,0], 1:[3,"",0,1], 2:[0,"",3,2], 1:[1,"",6,3], ...
        .map(([i,s,o],z) => [i, s, o, z])
        // append label shift (S) to each, mapping [i,s,o,z] to [i,s,o,z,S]
        // 0:[2,"",0,0,0], 1:[3,"",0,1,0], 2:[0,"",3,2,1], 1:[1,"",6,3,2], ...
        .reduce((r,[i,s,o,z],j) => {
            // output is [dummy, ...(one output for each layer)]
            const prev = r[j]; // output for previous layer
            const [,,prevO,,prevS] = prev;
            // increment S if layer not skipped and y/order increases
            const S = prevS + Number(!skips[i] && o > prevO);
            return [...r, [i,s,o,z,S]];
        }, [[null,null,-1]]).slice(1)
        // sort [i,s,o,z,S] by original layer definition in HTML
        // 0:[2,"",0,0,0], 1:[3,"",0,1,0], 2:[0,"",3,2,1], 1:[1,"",6,3,2], ...
        .sort(([pi],[qi]) => pi - qi)
        // map each [i,s,o,z,S] to object {s,z,S}
        // 0:{...}, 1:{...}, 2:{...}
        .map(([_i,s,_o,z,S]) => ({s,z,S}));

    for (const [i, {z}] of order.entries())
        layers[i].style.zIndex = z;

    for (const [i, layer] of layers.entries()) {
        const s = ss[i];
        const y = getY(s);
        layer.classList[s.includes("h") ? "add" : "remove"]("h");
        layer.classList[s.includes("q") ? "add" : "remove"]("q");
        layer.classList[s.includes("f") ? "add" : "remove"]("f");
        layer.style.setProperty("--step-y", Number.isNaN(y) ? 0 : y);
        layer.style.setProperty("--step-c", Number(s.includes("c")));
        layer.style.setProperty("--step-u", Number(s.includes("u")));
        layer.style.setProperty("--step-r", Number(s.includes("r")));
        layer.style.setProperty("--label-shift", order[i].s);
    }

    return {layers, sss, quiets, t};

    function parse(choreography) {
        const result = choreography.trim().split("\n").map(x => x.trim().split(/ +/));
        for (const [i, x] of result.entries())
            result[i] = x.map((y, j) => y == "." ? result[i - 1][j] : y);
        return result;
    }

    function getY(s) {
        return parseInt(s, 10);
    }

    function getOrder(s) {
        const y = getY(s);
        return Number.isNaN(y) ? Infinity : y;
    }
}
