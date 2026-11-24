// All themes the Settings tab offers, in one shape:
//   { name, family, dark, accents: [names], defaultAccent, colors: { roles + accents } }
// Roles used by Theme.qml / Settings.qml, darkest to lightest on dark themes
// (on light themes crust/mantle/base run from darker to lightest):
//   crust (bar) · mantle (panels) · base (cards) · surface0 · surface1 ·
//   overlay0 (dim text) · overlay2 · subtext0 · subtext1 (secondary text) · text ·
//   red · green · yellow (status colours)
// Catppuccin comes from palettes.js (generated); the others are hand-copied from
// each theme's official palette. Shades a theme doesn't define are marked "derived".
.pragma library
.import "palettes.js" as Ctp

var themes = {};
var order = [];

// ---- Catppuccin ------------------------------------------------------------
for (const id of Ctp.order) {
    const f = Ctp.flavours[id];
    themes[id] = {
        name: f.name, family: "Catppuccin", dark: f.dark,
        accents: Ctp.accents, defaultAccent: "sapphire", colors: f.colors,
    };
    order.push(id);
}

function add(id, t) { themes[id] = t; order.push(id); }

// ---- Tokyo Night (night) · github.com/folke/tokyonight.nvim ------------------
add("tokyonight", {
    name: "Tokyo Night", family: "Tokyo Night", dark: true,
    accents: ["red", "orange", "yellow", "green", "teal", "cyan", "blue", "purple", "magenta"],
    defaultAccent: "blue",
    colors: {
        crust: "#16161e", mantle: "#1a1b26", base: "#1f2335", surface0: "#292e42", surface1: "#3b4261",
        overlay0: "#565f89", overlay2: "#737aa2", subtext0: "#a9b1d6", subtext1: "#a9b1d6", text: "#c0caf5",
        red: "#f7768e", orange: "#ff9e64", yellow: "#e0af68", green: "#9ece6a", teal: "#73daca",
        cyan: "#7dcfff", blue: "#7aa2f7", purple: "#9d7cd8", magenta: "#bb9af7",
    },
});

// ---- Nord · nordtheme.com ------------------------------------------------------
add("nord", {
    name: "Nord", family: "Nord", dark: true,
    accents: ["red", "orange", "yellow", "green", "frost", "cyan", "blue", "deepblue", "purple"],
    defaultAccent: "cyan",
    colors: {
        crust: "#242933" /* derived: darker than nord0 */, mantle: "#2e3440", base: "#3b4252",
        surface0: "#434c5e", surface1: "#4c566a", overlay0: "#616e88" /* derived */, overlay2: "#7b88a1" /* derived */,
        subtext0: "#d8dee9", subtext1: "#e5e9f0", text: "#eceff4",
        red: "#bf616a", orange: "#d08770", yellow: "#ebcb8b", green: "#a3be8c", frost: "#8fbcbb",
        cyan: "#88c0d0", blue: "#81a1c1", deepblue: "#5e81ac", purple: "#b48ead",
    },
});

// ---- Gruvbox (dark) · github.com/morhetz/gruvbox --------------------------------
add("gruvbox", {
    name: "Gruvbox", family: "Gruvbox", dark: true,
    accents: ["red", "orange", "yellow", "green", "aqua", "blue", "purple"],
    defaultAccent: "orange",
    colors: {
        crust: "#1d2021", mantle: "#282828", base: "#32302f", surface0: "#3c3836", surface1: "#504945",
        overlay0: "#7c6f64", overlay2: "#928374", subtext0: "#a89984", subtext1: "#d5c4a1", text: "#ebdbb2",
        red: "#fb4934", orange: "#fe8019", yellow: "#fabd2f", green: "#b8bb26", aqua: "#8ec07c",
        blue: "#83a598", purple: "#d3869b",
    },
});

// ---- Rosé Pine (main and dawn) · rosepinetheme.com ------------------------------
add("rosepine", {
    name: "Rosé Pine", family: "Rosé Pine", dark: true,
    accents: ["love", "gold", "rose", "pine", "foam", "iris"],
    defaultAccent: "iris",
    colors: {
        crust: "#191724", mantle: "#1f1d2e", base: "#26233a", surface0: "#403d52", surface1: "#524f67",
        overlay0: "#6e6a86", overlay2: "#908caa", subtext0: "#908caa", subtext1: "#908caa", text: "#e0def4",
        red: "#eb6f92", green: "#9ccfd8", yellow: "#f6c177",
        love: "#eb6f92", gold: "#f6c177", rose: "#ebbcba", pine: "#31748f", foam: "#9ccfd8", iris: "#c4a7e7",
    },
});
add("rosepinedawn", {
    name: "Rosé Pine Dawn", family: "Rosé Pine", dark: false,
    accents: ["love", "gold", "rose", "pine", "foam", "iris"],
    defaultAccent: "pine",
    colors: {
        crust: "#f2e9e1", mantle: "#faf4ed", base: "#fffaf3", surface0: "#dfdad9", surface1: "#cecacd",
        overlay0: "#9893a5", overlay2: "#797593", subtext0: "#797593", subtext1: "#6e6a86" /* derived */, text: "#575279",
        red: "#b4637a", green: "#286983", yellow: "#ea9d34",
        love: "#b4637a", gold: "#ea9d34", rose: "#d7827e", pine: "#286983", foam: "#56949f", iris: "#907aa9",
    },
});

// ---- Dracula · draculatheme.com ---------------------------------------------------
add("dracula", {
    name: "Dracula", family: "Dracula", dark: true,
    accents: ["red", "orange", "yellow", "green", "cyan", "purple", "pink"],
    defaultAccent: "purple",
    colors: {
        crust: "#191a21", mantle: "#21222c", base: "#282a36", surface0: "#343746", surface1: "#44475a",
        overlay0: "#6272a4", overlay2: "#7c8bbd" /* derived */,
        subtext0: "#bfc3d6" /* derived */, subtext1: "#dcdee8" /* derived */, text: "#f8f8f2",
        red: "#ff5555", orange: "#ffb86c", yellow: "#f1fa8c", green: "#50fa7b", cyan: "#8be9fd",
        purple: "#bd93f9", pink: "#ff79c6",
    },
});

// ---- Everforest (dark, medium) · github.com/sainnhe/everforest --------------------
add("everforest", {
    name: "Everforest", family: "Everforest", dark: true,
    accents: ["red", "orange", "yellow", "green", "aqua", "blue", "purple"],
    defaultAccent: "green",
    colors: {
        crust: "#232a2e", mantle: "#2d353b", base: "#343f44", surface0: "#3d484d", surface1: "#475258",
        overlay0: "#7a8478", overlay2: "#9da9a0", subtext0: "#9da9a0", subtext1: "#b9b8a0" /* derived */, text: "#d3c6aa",
        red: "#e67e80", orange: "#e69875", yellow: "#dbbc7f", green: "#a7c080", aqua: "#83c092",
        blue: "#7fbbb3", purple: "#d699b6",
    },
});

// ---- Kanagawa (wave) · github.com/rebelot/kanagawa.nvim ---------------------------
add("kanagawa", {
    name: "Kanagawa", family: "Kanagawa", dark: true,
    accents: ["red", "orange", "yellow", "green", "aqua", "springblue", "crystalblue", "violet", "pink"],
    defaultAccent: "crystalblue",
    colors: {
        crust: "#16161d", mantle: "#1f1f28", base: "#2a2a37", surface0: "#363646", surface1: "#54546d",
        overlay0: "#727169", overlay2: "#938aa9", subtext0: "#c8c093", subtext1: "#c8c093", text: "#dcd7ba",
        red: "#e46876", orange: "#ffa066", yellow: "#e6c384", green: "#98bb6c", aqua: "#7aa89f",
        springblue: "#7fb4ca", crystalblue: "#7e9cd8", violet: "#957fb8", pink: "#d27e99",
    },
});

function get(id) { return themes[id] ?? themes.mocha; }

// The accent the user picked if this theme has it, else the theme's default.
function accentOf(theme, wanted) {
    return theme.accents.includes(wanted) ? wanted : theme.defaultAccent;
}
