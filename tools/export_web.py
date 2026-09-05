#!/usr/bin/env python3
"""Export Eleblorb for web and turn Godot's boot overlay into one loader."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "build" / "web" / "index.html"
GODOT = Path("/Applications/Godot.app/Contents/MacOS/Godot")

STYLE_END = "\t\t</style>"
SPLASH_IMAGE = '\t\t\t<img id="status-splash" class="show-image--false fullsize--true use-filter--true" src="index.png" alt="">\n'
PROGRESS_ELEMENT = '\t\t\t<progress id="status-progress"></progress>'
STATUS_VARIABLES = """\tconst statusProgress = document.getElementById('status-progress');
\tconst statusNotice = document.getElementById('status-notice');"""
PROGRESS_VISIBILITY = "\t\tstatusProgress.style.display = mode === 'progress' ? 'block' : 'none';"
PROGRESS_CALLBACK = """\t\t\t'onProgress': function (current, total) {
\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\tstatusProgress.value = current;
\t\t\t\t\tstatusProgress.max = total;
\t\t\t\t} else {
\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t\t}
\t\t\t},"""
ENGINE_END = """\t\t}).then(() => {
\t\t\tsetStatusMode('hidden');"""

LOADER_CSS = r"""

:root {
	--eleblorb-ui-font: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
	--eleblorb-vv-left: 0px;
	--eleblorb-vv-top: 0px;
	--eleblorb-vv-width: 100vw;
	--eleblorb-vv-height: 100vh;
}

#canvas, #status {
	position: fixed !important;
	left: var(--eleblorb-vv-left) !important;
	top: var(--eleblorb-vv-top) !important;
	right: auto !important;
	bottom: auto !important;
	width: var(--eleblorb-vv-width) !important;
	height: var(--eleblorb-vv-height) !important;
}

#status {
	box-sizing: border-box;
	background: #090e13;
	color: #f7edd9;
	font-family: var(--eleblorb-ui-font);
	padding: max(24px, env(safe-area-inset-top)) max(24px, env(safe-area-inset-right)) max(24px, env(safe-area-inset-bottom)) max(24px, env(safe-area-inset-left));
	z-index: 2147482999;
	opacity: 1;
	transition: opacity 350ms cubic-bezier(.22, 1, .36, 1);
}

#status.eleblorb-ready { opacity: 0; }

#loading-content {
	display: flex;
	width: min(780px, calc(100vw - 48px));
	flex-direction: column;
	align-items: stretch;
	gap: 24px;
	text-align: center;
}

#loading-title {
	margin: 0;
	font: 700 clamp(38px, 7vw, 72px)/1 var(--eleblorb-ui-font);
	letter-spacing: -.03em;
}

#loading-controls {
	display: none;
	min-height: 132px;
	align-items: center;
	justify-content: center;
}

.loader-desktop { display: flex; gap: clamp(24px, 6vw, 60px); }
.loader-mobile, .loader-controller { display: none; }
.loader-control { display: flex; min-width: 150px; flex-direction: column; align-items: center; gap: 12px; }
.loader-copy { color: #ccbaa0; font-size: 16px; line-height: 1.35; }
.keys { display: flex; align-items: center; gap: 6px; }
.key, .mouse {
	display: grid;
	box-sizing: border-box;
	place-items: center;
	border: 2px solid rgba(255,255,255,.85);
	background: rgba(99,51,61,.88);
	color: #f7edd9;
}
.key { width: 38px; height: 38px; border-radius: 12px; font-size: 14px; }
.key.wide { width: 112px; }
.mouse { width: 42px; height: 62px; border-radius: 20px; }
.mouse::before { content: ''; width: 3px; height: 13px; margin-top: -18px; border-radius: 2px; background: #f7edd9; }
.joystick {
	position: relative;
	width: 116px;
	height: 116px;
	box-sizing: border-box;
	border: 7px solid rgba(247,237,217,.32);
	border-radius: 38px;
}
.joystick::after {
	content: '';
	position: absolute;
	top: 50%; left: 50%;
	width: 50px; height: 50px;
	border-radius: 17px;
	background: rgba(247,237,217,.9);
	animation: eleblorb-joystick 5.2s ease-in-out infinite;
}
@keyframes eleblorb-joystick {
	0%, 50%, 100% { transform: translate(-50%, -50%); }
	12.5% { transform: translate(calc(-50% - 12px), calc(-50% - 9px)); }
	25% { transform: translate(-50%, -50%); }
	37.5% { transform: translate(calc(-50% + 12px), calc(-50% + 9px)); }
}

#loading-tip {
	box-sizing: border-box;
	min-height: 74px;
	margin: 0;
	padding: 18px 24px;
	border-radius: 28px;
	background: rgba(41,28,18,.55);
	color: #ccbaa0;
	font-size: 16px;
	line-height: 1.45;
	display: grid;
	place-items: center;
}

#status-phase { color: #ccbaa0; font-size: 14px; line-height: 1.2; }
#status-progress {
	appearance: none;
	-webkit-appearance: none;
	position: static;
	width: 100%;
	height: 12px;
	margin: 0;
	border: 0;
	border-radius: 999px;
	background: rgba(204,186,160,.24);
	overflow: hidden;
}
#status-progress::-webkit-progress-bar { background: rgba(204,186,160,.24); }
#status-progress::-webkit-progress-value { background: #d78698; border-radius: 999px; }
#status-progress::-moz-progress-bar { background: #d78698; border-radius: 999px; }

body.gamepad-connected .loader-desktop { display: none; }
body.gamepad-connected .loader-controller { display: flex; }

@media (max-width: 700px) {
	#loading-content { gap: 18px; }
	#loading-controls { min-height: 156px; }
	.loader-desktop { flex-wrap: wrap; gap: 16px; }
	.loader-control { min-width: 96px; }
	#loading-tip { min-height: 86px; padding: 16px 18px; }
}

@media (hover: none) and (pointer: coarse) {
	.loader-desktop { display: none; }
	.loader-mobile { display: flex; flex-direction: column; align-items: center; gap: 16px; }
	body.gamepad-connected .loader-mobile { display: none; }
	body.gamepad-connected .loader-controller { display: flex; }
}

@media (prefers-reduced-motion: reduce) {
	.joystick::after { animation: none; transform: translate(-50%, -50%); }
	#status { transition-duration: 1ms; }
}
"""

LOADER_HTML = """\t\t\t<div id="loading-content">
\t\t\t\t<h1 id="loading-title">Eleblorb</h1>
\t\t\t\t<div id="loading-controls" aria-label="Controls">
\t\t\t\t\t<div class="loader-desktop">
\t\t\t\t\t\t<div class="loader-control"><div class="keys" aria-hidden="true"><span class="key">W</span><span class="key">A</span><span class="key">S</span><span class="key">D</span></div><span class="loader-copy">Move</span></div>
\t\t\t\t\t\t<div class="loader-control"><div class="mouse" aria-hidden="true"></div><span class="loader-copy">Look around</span></div>
\t\t\t\t\t\t<div class="loader-control"><div class="key wide" aria-hidden="true">SPACE</div><span class="loader-copy">Jump</span></div>
\t\t\t\t\t</div>
\t\t\t\t\t<div class="loader-controller"><span class="loader-copy">Left Stick to move · Right Stick to look · Y to jump</span></div>
\t\t\t\t\t<div class="loader-mobile"><div class="joystick" aria-hidden="true"></div><span class="loader-copy">Drag to move · Drag the world to look</span></div>
\t\t\t\t</div>
\t\t\t\t<p id="loading-tip">Press F near people, objects, and Blorbs to interact.</p>
\t\t\t\t<div id="status-phase" role="status" aria-live="polite">Preparing Eleblorb…</div>
\t\t\t\t<progress id="status-progress" max="1" value="0" aria-label="Loading progress"></progress>
\t\t\t</div>"""

STATUS_VARIABLES_WITH_LOADER = STATUS_VARIABLES + """
\tconst statusPhase = document.getElementById('status-phase');
\tconst loadingControls = document.getElementById('loading-controls');
\tconst loadingTip = document.getElementById('loading-tip');

\tconst desktopTips = [
\t\t'Press F near people, objects, and Blorbs to interact.',
\t\t'Press Tab to open Items, Blorbs, and your Character.',
\t\t'Press T to toggle your Blorb suit.',
\t\t'Bounce off a Blorb and jump as you land to leap higher.',
\t\t'A compass can point you toward wild Blorbs.'
\t];
\tconst touchTips = [
\t\t'Tap an action when you are close enough to interact.',
\t\t'Open your inventory to see Items, Blorbs, and your Character.',
\t\t'Use the Blorb suit action to wear your party Blorbs.',
\t\t'Bounce off a Blorb and jump as you land to leap higher.',
\t\t'A compass can point you toward wild Blorbs.'
\t];
\tlet tipIndex = 0;
\tconst touchPrimary = window.matchMedia('(hover: none) and (pointer: coarse)');
\tsetInterval(() => {
\t\tconst tips = touchPrimary.matches ? touchTips : desktopTips;
\t\ttipIndex = (tipIndex + 1) % tips.length;
\t\tloadingTip.textContent = tips[tipIndex];
\t}, 3200);

\twindow.addEventListener('gamepadconnected', () => document.body.classList.add('gamepad-connected'));
\twindow.addEventListener('gamepaddisconnected', () => document.body.classList.remove('gamepad-connected'));

\tfunction syncVisibleViewport(notifyGodot) {
\t\tconst viewport = window.visualViewport;
\t\tconst left = viewport ? viewport.pageLeft : (window.scrollX || 0);
\t\tconst top = viewport ? viewport.pageTop : (window.scrollY || 0);
\t\tconst width = viewport ? viewport.width : window.innerWidth;
\t\tconst height = viewport ? viewport.height : window.innerHeight;
\t\tconst style = document.documentElement.style;
\t\tstyle.setProperty('--eleblorb-vv-left', left + 'px');
\t\tstyle.setProperty('--eleblorb-vv-top', top + 'px');
\t\tstyle.setProperty('--eleblorb-vv-width', width + 'px');
\t\tstyle.setProperty('--eleblorb-vv-height', height + 'px');
\t\tif (notifyGodot) requestAnimationFrame(() => window.dispatchEvent(new Event('resize')));
\t}
\tsyncVisibleViewport(false);
\twindow.addEventListener('resize', () => syncVisibleViewport(false));
\tif (window.visualViewport) {
\t\twindow.visualViewport.addEventListener('resize', () => syncVisibleViewport(true));
\t\twindow.visualViewport.addEventListener('scroll', () => syncVisibleViewport(false));
\t}

\twindow.eleblorbLoadingPhase = function (text, progress) {
\t\tstatusPhase.textContent = text;
\t\tif (Number.isFinite(progress)) {
\t\t\tstatusProgress.max = 1;
\t\t\tstatusProgress.value = Math.max(0, Math.min(1, progress));
\t\t}
\t};
\twindow.eleblorbWorldReady = function () {
\t\twindow.eleblorbLoadingPhase('Ready', 1);
\t\trequestAnimationFrame(() => requestAnimationFrame(() => {
\t\t\tstatusOverlay.classList.add('eleblorb-ready');
\t\t\tsetTimeout(() => {
\t\t\t\tstatusOverlay.remove();
\t\t\t\tinitializing = false;
\t\t\t\tdocument.getElementById('canvas').focus();
\t\t\t}, 350);
\t\t}));
\t};"""

PROGRESS_AND_LOADER_VISIBILITY = """\t\tstatusProgress.style.display = mode === 'progress' ? 'block' : 'none';
\t\tstatusPhase.style.display = mode === 'progress' ? 'block' : 'none';
\t\tloadingControls.style.display = mode === 'progress' ? 'flex' : 'none';
\t\tloadingTip.style.display = mode === 'progress' ? 'grid' : 'none';"""

WHOLE_LAUNCH_PROGRESS = """\t\t\t'onProgress': function (current, total) {
\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\tconst ratio = Math.min(current / total, 1);
\t\t\t\t\twindow.eleblorbLoadingPhase(ratio >= 1 ? 'Starting Eleblorb…' : 'Downloading Eleblorb…', ratio * 0.9);
\t\t\t\t} else {
\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\tstatusPhase.textContent = 'Preparing Eleblorb…';
\t\t\t\t}
\t\t\t},"""

WAIT_FOR_WORLD = """\t\t}).then(() => {
\t\t\twindow.eleblorbLoadingPhase('Building the world…', 0.92);"""


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one {label} marker, found {count}")
    return source.replace(old, new, 1)


def patch_html() -> None:
    html = HTML.read_text(encoding="utf-8")
    html = replace_once(html, "<title>Eleblorb</title>", "<title>Eleblorb</title>", "title")
    html = replace_once(html, STYLE_END, LOADER_CSS + STYLE_END, "style end")
    html = replace_once(html, SPLASH_IMAGE, "", "unused splash image")
    html = replace_once(html, PROGRESS_ELEMENT, LOADER_HTML, "progress element")
    html = replace_once(html, STATUS_VARIABLES, STATUS_VARIABLES_WITH_LOADER, "status variables")
    html = replace_once(html, PROGRESS_VISIBILITY, PROGRESS_AND_LOADER_VISIBILITY, "progress visibility")
    html = replace_once(html, PROGRESS_CALLBACK, WHOLE_LAUNCH_PROGRESS, "progress callback")
    html = replace_once(html, ENGINE_END, WAIT_FOR_WORLD, "engine completion")
    HTML.write_text(html.rstrip() + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--patch-only", action="store_true", help="Patch an existing build/web/index.html")
    args = parser.parse_args()

    if not args.patch_only:
        HTML.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [str(GODOT), "--headless", "--path", str(ROOT), "--export-release", "Web", str(HTML)],
            cwd=ROOT,
            check=True,
        )
    if not HTML.exists():
        raise FileNotFoundError(f"No exported HTML at {HTML}")
    patch_html()
    print(f"Exported one continuous Eleblorb loader: {HTML}")


if __name__ == "__main__":
    main()
