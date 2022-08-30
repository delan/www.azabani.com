function _hpdemo(state, root, t = 0) {
    const choreography = root.querySelector(":scope script");
    const main = root.querySelector(":scope main");
    const layers = state.layers ?? [...main.children];
    const sss = state.sss ?? parse(choreography.textContent);
    const quiets = state.quiets ?? getInitiallyQuiets(layers);
    const ss = sss[t = Math.min(Math.max(t, 0), sss.length - 1)];

    const skips = ss.map((s, i) => quiets[i] || /[qur]/.test(s));
    const order = ss
        // 0:["",0], 1:["",1], 2:["",2], ...
        .map((s, i) => [s, i])
        // 0:["",2], 1:["",0], 2:["",1], ...
        .sort(([ps, pi], [qs, qi]) => {
            const dOrder = getOrder(ps) - getOrder(qs);
            return dOrder || pi - qi;
        })
        // z  i z   z  i z   z  i z
        // 0:[2,0], 1:[0,1], 2:[1,2], ...
        .map(([_, i], z) => [i, z])
        // z  i z s   z  i z s   z  i z s
        // 0:[2,0,0], 1:[0,1,1], 2:[1,2,1], ...
        .reduce((r,[i,z],j) => [...r, [i, z, r[j][2] + Number(!skips[i])]], [[null,null,-1]]).slice(1)
        // i  i z s   i  i z s   i  i z s
        // 0:[0,1,1], 1:[1,2,1], 2:[2,0,0]
        .sort(([pi, _pz, _ps], [qi, _qz, _qs]) => pi - qi)
        // 0:{...}, 1:{...}, 2:{...}
        .map(([_i, z, s]) => ({z, s}));

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

    function getInitiallyQuiets(layers) {
        return layers.map(x => x.classList.contains("q"));
    }

    function getY(s) {
        return parseInt(s, 10);
    }

    function getOrder(s) {
        const y = getY(s);
        return Number.isNaN(y) ? Infinity : y;
    }
}
