'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const script = path.join(__dirname, 'prepare_vscode_android.ps1');
const fakeToken = 'fixture-debug-token';
// The source job runs on Linux; the Windows launcher job runs these fixtures.
const windowsOnly = {skip: process.platform !== 'win32' && 'Requires Windows PowerShell.'};

function fixture(change = () => {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'healthmate-vscode-'));
  const project = path.join(root, 'project');
  const local = path.join(root, 'private-local');
  fs.mkdirSync(path.join(project, 'config'), {recursive: true});
  fs.mkdirSync(path.join(local, 'HealthMate'), {recursive: true});
  fs.writeFileSync(path.join(project, 'config/admin-runtime.json'), JSON.stringify({HEALTHMATE_ENABLE_ADMIN_CONTROLS: true}));
  fs.writeFileSync(path.join(project, 'config/chat-api.json'), JSON.stringify({HEALTHMATE_CHAT_API_URL: 'https://example.com/v1/chat'}));
  const token = path.join(local, 'HealthMate/app-check-debug-token.txt');
  const output = path.join(local, 'HealthMate/vscode-android-debug.json');
  fs.writeFileSync(token, fakeToken);
  change({root, project, local, token, output});
  try {
    const result = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, '-ProjectRoot', project], {
      encoding: 'utf8', windowsHide: true, env: {...process.env, LOCALAPPDATA: local},
    });
    assert.ok(!`${result.stdout}${result.stderr}`.includes(fakeToken), 'never print the token');
    return {result, config: fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : null};
  } finally {
    assert.ok(root.startsWith(path.join(os.tmpdir(), 'healthmate-vscode-')));
    fs.rmSync(root, {recursive: true, force: true});
  }
}

test('F5 prepares private defines with the shared runtime and token, without printing secrets', windowsOnly, () => {
  const {result, config} = fixture();
  assert.equal(result.status, 0, result.stderr);
  assert.equal(config.HEALTHMATE_ENABLE_ADMIN_CONTROLS, true);
  assert.equal(config.HEALTHMATE_APP_CHECK_DEBUG_TOKEN, fakeToken);
  assert.equal(config.HEALTHMATE_CHAT_API_URL, 'https://example.com/v1/chat');
});

test('missing and empty token stop preparation without generating a default config', windowsOnly, () => {
  for (const change of [({token}) => fs.unlinkSync(token), ({token}) => fs.writeFileSync(token, ' ')]) {
    const {result, config} = fixture(change);
    assert.notEqual(result.status, 0);
    assert.equal(config, null);
  }
});

test('a disabled runtime or a conflicting chat config fails closed', windowsOnly, () => {
  for (const change of [
    ({project}) => fs.writeFileSync(path.join(project, 'config/admin-runtime.json'), JSON.stringify({HEALTHMATE_ENABLE_ADMIN_CONTROLS: false})),
    ({project}) => fs.writeFileSync(path.join(project, 'config/chat-api.json'), JSON.stringify({HEALTHMATE_ENABLE_ADMIN_CONTROLS: false})),
  ]) {
    const {result, config} = fixture(change);
    assert.notEqual(result.status, 0);
    assert.equal(config, null);
  }
});

test('the debug file cannot be written into the repository', windowsOnly, () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'healthmate-vscode-'));
  try {
    const denied = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, '-ProjectRoot', root], {
      encoding: 'utf8', windowsHide: true, env: {...process.env, LOCALAPPDATA: root},
    });
    assert.notEqual(denied.status, 0);
    assert.equal(fs.existsSync(path.join(root, 'HealthMate/vscode-android-debug.json')), false);
  } finally {
    assert.ok(root.startsWith(path.join(os.tmpdir(), 'healthmate-vscode-')));
    fs.rmSync(root, {recursive: true, force: true});
  }
});

test('VS Code launch wires the private define file and the matching prepare task', () => {
  const launch = fs.readFileSync(path.join(__dirname, '../.vscode/launch.json'), 'utf8');
  const tasks = JSON.parse(fs.readFileSync(path.join(__dirname, '../.vscode/tasks.json'), 'utf8'));
  assert.ok(launch.includes('"preLaunchTask": "HealthMate: prepare Android debug"'));
  assert.ok(launch.includes('--dart-define-from-file=${env:LOCALAPPDATA}/HealthMate/vscode-android-debug.json'));
  const task = tasks.tasks.find(item => item.label === 'HealthMate: prepare Android debug');
  assert.ok(task.args.includes('${workspaceFolder}/tool/prepare_vscode_android.ps1'));
  assert.ok(!launch.includes(fakeToken));
});
