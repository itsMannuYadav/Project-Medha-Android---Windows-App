// One-off generator for the Medha icon set (assets/icons/*.svg).
// Paths are lifted from the Claude Design canvas artboards so Flutter icons
// match the mockups pixel-for-pixel. Safe to re-run; overwrites in place.
import { writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, "..", "assets", "icons");
mkdirSync(outDir, { recursive: true });

const wrap = (inner, extraAttrs = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"${extraAttrs}>${inner}</svg>\n`;

const icons = {
  home: wrap(`<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9a1 1 0 0 0 1 1h3v-5h4v5h3a1 1 0 0 0 1-1v-9"/>`),
  modules: wrap(`<path d="M12 3 3 8l9 5 9-5-9-5Z"/><path d="M3 12l9 5 9-5"/>`),
  tools_grid: wrap(`<rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/>`),
  calendar_check: wrap(`<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17"/><path d="M8 3v4M16 3v4"/><path d="m8.5 14 2 2 4-4"/>`),
  calendar: wrap(`<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17"/><path d="M8 3v4M16 3v4"/>`),
  user: wrap(`<circle cx="12" cy="8.5" r="3.5"/><path d="M5 20c1.2-4 4.2-6 7-6s5.8 2 7 6"/>`),
  send: wrap(`<path d="M20.5 3.5 3 10.2c-.7.27-.68 1.26.03 1.5l6.2 2.1 2.1 6.2c.24.71 1.23.73 1.5.03L20.5 3.5Z"/><path d="M20.5 3.5 9.6 14.4"/>`, ' stroke-width="2"'),
  mic: wrap(`<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0"/><path d="M12 17.5V21M9 21h6"/>`),
  chevron_down: wrap(`<path d="m6 9 6 6 6-6"/>`, ' stroke-width="2.2"'),
  chevron_left: wrap(`<path d="m15 18-6-6 6-6"/>`, ' stroke-width="1.9"'),
  chevron_right: wrap(`<path d="m9 18 6-6-6-6"/>`, ' stroke-width="2"'),
  search: wrap(`<circle cx="11" cy="11" r="6.5"/><path d="m20 20-4.3-4.3"/>`),
  bell: wrap(`<path d="M6 10a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 14 6 10Z"/><path d="M10 19a2 2 0 0 0 4 0"/>`),
  globe: wrap(`<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.2 2.3 3.3 5.3 3.3 8.5s-1.1 6.2-3.3 8.5c-2.2-2.3-3.3-5.3-3.3-8.5S9.8 5.8 12 3.5Z"/>`),
  download: wrap(`<path d="M12 4v11"/><path d="m7.5 11 4.5 4.5L16.5 11"/><path d="M5 19.5h14"/>`),
  presentation: wrap(`<rect x="3.5" y="4.5" width="17" height="11" rx="1.5"/><path d="M8 20l4-4.5L16 20"/><path d="M9 8.5h6M9 11.5h4"/>`),
  mindmap: wrap(`<circle cx="12" cy="5.5" r="2"/><circle cx="5.5" cy="14" r="2"/><circle cx="18.5" cy="14" r="2"/><circle cx="12" cy="19.5" r="1.6"/><path d="M12 7.5v3M10.3 9.3 7 12.4M13.7 9.3 17 12.4M9 15.3l2 2.3M15 15.3l-2 2.3"/>`),
  help_circle: wrap(`<circle cx="12" cy="12" r="8.5"/><path d="M9.5 9.3a2.5 2.5 0 1 1 3.5 2.3c-.9.5-1.3.9-1.3 1.9"/><path d="M12 17.2v.1"/>`),
  activity: wrap(`<path d="M3.5 12h4l2-6 4 12 2-6h4"/>`),
  clock: wrap(`<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>`),
  users_group: wrap(`<circle cx="9" cy="8.5" r="3"/><path d="M3.5 19c.8-3.3 3-5 5.5-5s4.7 1.7 5.5 5"/><circle cx="17" cy="9.5" r="2.4"/><path d="M15.5 13.2c2 .2 3.6 1.7 4.2 4.3"/>`),
  dice: wrap(`<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="8.3" cy="8.3" r="1.1" fill="#000000" stroke="none"/><circle cx="15.7" cy="8.3" r="1.1" fill="#000000" stroke="none"/><circle cx="12" cy="12" r="1.1" fill="#000000" stroke="none"/><circle cx="8.3" cy="15.7" r="1.1" fill="#000000" stroke="none"/><circle cx="15.7" cy="15.7" r="1.1" fill="#000000" stroke="none"/>`),
  translate: wrap(`<path d="M4 5.5h9"/><path d="M8.5 3.5v2"/><path d="M6 5.5c.3 3 2.3 5.4 5 6.8"/><path d="M11 5.5c-.7 2.6-2.4 4.7-4.6 6.2"/><path d="M13.5 20.5 17.5 11l4 9.5"/><path d="M14.7 17.5h5.6"/>`),
  file_question: wrap(`<path d="M7 3.5h7l4 4v13a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1v-16a1 1 0 0 1 1-1Z"/><path d="M14 3.5V8h4"/><path d="M10.3 13.8a1.7 1.7 0 1 1 2.4 1.5c-.6.35-.9.6-.9 1.3"/><path d="M12 18.9v.1"/>`),
  clipboard: wrap(`<rect x="5.5" y="5" width="13" height="16" rx="2"/><rect x="9" y="3" width="6" height="3.5" rx="1"/><path d="M9 12h6M9 15.5h6M9 8.5h2"/>`),
  form: wrap(`<rect x="4.5" y="4" width="15" height="16" rx="2"/><path d="M8 9h8M8 12.5h8M8 16h5"/>`),
  eye: wrap(`<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z"/><circle cx="12" cy="12" r="3"/>`),
  eye_off: wrap(`<path d="M3 3l18 18"/><path d="M10.6 5.6A10.6 10.6 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a15.6 15.6 0 0 1-3.4 4.3M6.6 6.6C4.2 8.1 2.5 10.5 2.5 12c0 0 3.5 6.5 9.5 6.5 1.4 0 2.6-.3 3.7-.9"/><path d="M9.9 10a3 3 0 0 0 4.2 4.2"/>`),
  logout: wrap(`<path d="M9 4H6a1.5 1.5 0 0 0-1.5 1.5v13A1.5 1.5 0 0 0 6 20h3"/><path d="M14 16l4-4-4-4"/><path d="M18 12H9"/>`, ' stroke-width="1.9"'),
  shield_check: wrap(`<path d="M12 3.5 5 6.5v5c0 4.7 3 8 7 9 4-1 7-4.3 7-9v-5L12 3.5Z"/><path d="m9.3 12 1.8 1.8 3.6-3.8"/>`),
  refresh: wrap(`<path d="M20 12a8 8 0 1 1-2.9-6.2"/><path d="M20 4v5h-5"/>`, ' stroke-width="1.9"'),
  mail: wrap(`<path d="m3.5 6.5 8.5 6 8.5-6"/><rect x="3.5" y="5" width="17" height="14" rx="2"/>`),
  phone: wrap(`<rect x="7" y="2.5" width="10" height="19" rx="2"/><path d="M11 18.5h2"/>`),
  info_circle: wrap(`<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5"/><path d="M12 7.8v.1"/>`),
  plus: wrap(`<path d="M12 5v14M5 12h14"/>`, ' stroke-width="2"'),
  minus: wrap(`<path d="M5 12h14"/>`, ' stroke-width="2"'),
  book: wrap(`<path d="M4.5 5.5c2-1 4.5-1 7.5.5 3-1.5 5.5-1.5 7.5-.5v13c-2-1-4.5-1-7.5.5-3-1.5-5.5-1.5-7.5-.5Z"/><path d="M12 6v13"/>`),
  receipt: wrap(`<path d="M6 3.5h12v17l-2.2-1.4-2.2 1.4-1.6-1.4-1.6 1.4-2.2-1.4L6 20.5Z"/><path d="M9 8.5h6M9 12h6M9 15.5h3.5"/>`),
  megaphone: wrap(`<path d="M4 10.5v3a1.3 1.3 0 0 0 1.3 1.3H7l1 4.7h2l-.8-4.7h1.3l7 3V6.5l-7 3H5.3A1.3 1.3 0 0 0 4 10.8Z"/><path d="M19.5 9.5a4.5 4.5 0 0 1 0 5"/>`),
  report: wrap(`<rect x="4.5" y="3.5" width="15" height="17" rx="1.5"/><path d="M8 13.5v3M12 10.5v6M16 8v9"/>`),
  grid_calendar: wrap(`<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 10h17"/><path d="M8 3v4M16 3v4"/><path d="M8.5 13.5h1.5M11.3 13.5h1.5M14 13.5h1.5M8.5 17h1.5M11.3 17h1.5"/>`),
};

for (const [name, svg] of Object.entries(icons)) {
  writeFileSync(join(outDir, `${name}.svg`), svg, "utf8");
}
console.log(`wrote ${Object.keys(icons).length} icons to ${outDir}`);
