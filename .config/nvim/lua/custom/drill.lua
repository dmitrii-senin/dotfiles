-- Drill harness. Two modes:
--   :TextDrill [domain]  — scratch buffer + `claude -p` grading
--                          (consumes text-drill-corpus.md, td-* drills)
--   :Drill     [domain]  — floating prompt + self-report, you work in
--                          your own buffers (consumes motion-corpus.md)
--
-- Shared keymaps once a session is active:
--   <localleader>g  grade / done    (text: send to claude;  motion: mark done)
--   <localleader>r  reveal target   (= stuck; resets box to 1)
--   <localleader>R  reset to before (text mode only)
--   <localleader>s  skip
--   <localleader>n  next
--   <localleader>q  quit session
--
-- Text-mode keymaps are buffer-local on the scratch buffer.
-- Motion-mode keymaps are global, registered on session start and
-- removed on session end.

local M = {}

local TEXT_CORPUS   = vim.fn.expand('~/.claude/skills/neovim/topics/drills/text-drill-corpus.md')
local MOTION_CORPUS = vim.fn.expand('~/.claude/skills/neovim/topics/drills/motion-corpus.md')
local STATE         = vim.fn.expand('~/.claude/skills/neovim/references/drill-state.md')
local CURSOR        = '\xe2\x96\x88'  -- U+2588 FULL BLOCK

-- session = { mode = 'text'|'motion', drills, idx, current, results,
--             scratch_buf?, prompt_win?, prompt_buf? }
local session = nil

-- ─── Corpus parsers ───────────────────────────────────────────────
local function parse_text_corpus()
  local out, cur, mode, in_code, buf = {}, nil, nil, false, {}
  for _, ln in ipairs(vim.fn.readfile(TEXT_CORPUS)) do
    local id, meta = ln:match('^### (td%-%d+)%s*%*%((.-)%)%*')
    if id then
      if cur then table.insert(out, cur) end
      cur = { id = id, tags = {}, level = 1 }
      for tok in meta:gmatch('([^,]+)') do
        tok = vim.trim(tok):gsub('^tags:%s*', '')
        local lv = tok:match('^level:(%d+)$')
        if lv then cur.level = tonumber(lv)
        elseif tok ~= '' then table.insert(cur.tags, tok) end
      end
      mode, in_code, buf = nil, false, {}
    elseif cur then
      if ln:match('^%*%*Before:%*%*') then mode = 'before'
      elseif ln:match('^%*%*After:%*%*') then mode = 'after'
      elseif ln:match('^```') then
        if in_code then cur[mode] = buf; in_code, buf = false, {}
        else in_code = true end
      elseif in_code then table.insert(buf, ln)
      else
        local t = ln:match('^%- %*%*target%*%*:%s*`(.+)`%s*$')
        if t then cur.target = t end
      end
    end
  end
  if cur then table.insert(out, cur) end
  return out
end

local function parse_motion_corpus()
  local out, cur = {}, nil
  for _, ln in ipairs(vim.fn.readfile(MOTION_CORPUS)) do
    local id, meta = ln:match('^### ([%w]+%-%d+)%s*%*%((.-)%)%*')
    if id then
      if cur then table.insert(out, cur) end
      cur = { id = id, tags = {}, level = 1 }
      for tok in meta:gmatch('([^,]+)') do
        tok = vim.trim(tok):gsub('^tags:%s*', '')
        local lv = tok:match('^level:(%d+)$')
        if lv then cur.level = tonumber(lv)
        elseif tok ~= '' then table.insert(cur.tags, tok) end
      end
    elseif cur then
      local p = ln:match('^%- %*%*prompt%*%*:%s*(.+)$')
      if p then cur.prompt = p end
      local t = ln:match('^%- %*%*target%*%*:%s*(.+)$')
      if t then cur.target = t end
      local a = ln:match('^%- %*%*accept%*%*:%s*(.+)$')
      if a then cur.accept = a end
    end
  end
  if cur then table.insert(out, cur) end
  return out
end

local function strip_cursor(lines)
  for i, ln in ipairs(lines) do
    local s = ln:find(CURSOR, 1, true)
    if s then
      local stripped = ln:sub(1, s-1) .. ln:sub(s + #CURSOR)
      local copy = vim.deepcopy(lines)
      copy[i] = stripped
      local col = s - 1
      if col >= #stripped and #stripped > 0 then col = #stripped - 1 end
      return copy, i, math.max(0, col)
    end
  end
  return lines, 1, 0
end

-- ─── State (drill-state.md) ────────────────────────────────────────
local function read_state()
  if vim.fn.filereadable(STATE) == 0 then return {} end
  local rows, in_table = {}, false
  for _, ln in ipairs(vim.fn.readfile(STATE)) do
    if ln:match('^## Drills') then in_table = true
    elseif in_table then
      if ln:match('^## ') then in_table = false
      else
        local id, attempts, _, _, last_seen, box =
          ln:match('^|%s*([%w%-]+)%s*|%s*(%d+)%s*|%s*(%d+)%s*|%s*(%d+)%s*|%s*(%S+)%s*|%s*(%d+)')
        if id then
          rows[id] = {
            attempts  = tonumber(attempts),
            last_seen = vim.trim(last_seen),
            box       = tonumber(box),
          }
        end
      end
    end
  end
  return rows
end

local function update_state(id, outcome, weak_keys_to_add)
  local lines = vim.fn.readfile(STATE)
  local today = os.date('%Y-%m-%d')
  for i, ln in ipairs(lines) do
    local row_id = ln:match('^|%s*([%w%-]+)%s*|')
    if row_id == id then
      local attempts, solved, stuck, _, box, weak, notes =
        ln:match('|%s*(%d+)%s*|%s*(%d+)%s*|%s*(%d+)%s*|%s*(%S+)%s*|%s*(%d+)%s*|%s*([^|]-)%s*|%s*([^|]-)%s*|')
      attempts, solved, stuck, box = tonumber(attempts), tonumber(solved), tonumber(stuck), tonumber(box)
      attempts = attempts + 1
      if outcome == 'solved' then
        solved = solved + 1
        box = math.min(box + 1, 4)
      else
        stuck = stuck + 1
        box = 1
        if weak_keys_to_add then
          local set = {}
          for k in (weak or ''):gmatch('([^,%s]+)') do set[k] = true end
          for _, k in ipairs(weak_keys_to_add) do set[k] = true end
          local keys = {}
          for k in pairs(set) do table.insert(keys, k) end
          table.sort(keys)
          weak = table.concat(keys, ', ')
        end
      end
      lines[i] = string.format('| %-6s | %-8d | %-6d | %-5d | %-11s | %-3d | %-14s | %s |',
        id, attempts, solved, stuck, today, box, weak or '', notes or '')
      break
    end
  end
  for i, ln in ipairs(lines) do
    if ln:match('^last_practiced:') then
      lines[i] = 'last_practiced: ' .. today
      break
    end
  end
  vim.fn.writefile(lines, STATE)
end

-- ─── Selection ─────────────────────────────────────────────────────
local function days_ago(date_str, now)
  if date_str == '-' or date_str == '' then return math.huge end
  local y, m, d = date_str:match('(%d+)-(%d+)-(%d+)')
  if not y then return math.huge end
  local t = os.time{ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }
  return math.floor((now - t) / 86400)
end

local TEXT_DOMAIN_TAG = {
  motions = 'motion', textobjects = 'textobject', operators = 'operator',
  insert = 'insert', substitute = 'substitute',
}

local MOTION_DOMAIN_PREFIX = {
  hjkl = 'hd', word = 'wm', textobjects = 'to', ['text-objects'] = 'to',
  operators = 'op', search = 'ss', marks = 'mj', registers = 'rg',
  macros = 'mc', ex = 'ex', folds = 'fw', windows = 'fw',
  lsp = 'lsp', treesitter = 'ts', structural = 'ts',
}

local THRESHOLDS = { [1] = 0, [2] = 3, [3] = 7, [4] = 30 }

local function build_pool(drills, state, now, predicate)
  local pool = {}
  for _, d in ipairs(drills) do
    if predicate(d) then
      local s = state[d.id] or { box = 1, attempts = 0, last_seen = '-' }
      if days_ago(s.last_seen, now) >= THRESHOLDS[s.box] then
        table.insert(pool, { drill = d, state = s })
      end
    end
  end
  table.sort(pool, function(a, b)
    if a.state.box ~= b.state.box then return a.state.box < b.state.box end
    if a.state.attempts ~= b.state.attempts then return a.state.attempts < b.state.attempts end
    return a.drill.id < b.drill.id
  end)
  return pool
end

local function take_n(pool, n)
  local picks = {}
  for i = 1, math.min(n, #pool) do picks[i] = pool[i].drill end
  return picks
end

local function select_text_drills(domain, n)
  local tag = TEXT_DOMAIN_TAG[domain]
  return take_n(build_pool(parse_text_corpus(), read_state(), os.time(), function(d)
    return not tag
      or vim.tbl_contains(d.tags, tag)
      or (domain == 'substitute' and vim.tbl_contains(d.tags, 'search'))
  end), n)
end

local function select_motion_drills(domain, n)
  local prefix = domain and (MOTION_DOMAIN_PREFIX[domain] or domain)
  return take_n(build_pool(parse_motion_corpus(), read_state(), os.time(), function(d)
    return not prefix or d.id:sub(1, #prefix + 1) == prefix .. '-'
  end), n)
end

-- ─── Text mode ─────────────────────────────────────────────────────
local function close_text_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(b):match('^drill://') then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function close_prompt_window()
  if session and session.prompt_win and vim.api.nvim_win_is_valid(session.prompt_win) then
    pcall(vim.api.nvim_win_close, session.prompt_win, true)
    session.prompt_win = nil
  end
end

local function open_float(lines)
  if not session.prompt_buf or not vim.api.nvim_buf_is_valid(session.prompt_buf) then
    session.prompt_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[session.prompt_buf].bufhidden = 'wipe'
  end
  vim.api.nvim_buf_set_lines(session.prompt_buf, 0, -1, false, lines)
  local width = 64
  for _, l in ipairs(lines) do if #l > width then width = math.min(#l + 2, vim.o.columns - 4) end end
  session.prompt_win = vim.api.nvim_open_win(session.prompt_buf, false, {
    relative = 'editor', anchor = 'NE',
    row = 1, col = vim.o.columns - 1,
    width = width, height = #lines,
    style = 'minimal', border = 'rounded',
    focusable = false, noautocmd = true,
    title = ' drill ', title_pos = 'left',
  })
end

local function wrap(text, width)
  local out = {}
  for line in (text or ''):gmatch('[^\n]+') do
    while #line > width do
      local cut = line:sub(1, width):find(' [^ ]*$') or width
      table.insert(out, line:sub(1, cut - 1))
      line = line:sub(cut + 1)
    end
    table.insert(out, line)
  end
  return out
end

local function show_text_target(drill)
  close_prompt_window()
  local lines = {
    string.format(' %s  (level %d, %s)', drill.id, drill.level, table.concat(drill.tags, ', ')),
    '',
    ' Edit the buffer to match this target (█ = cursor position):',
    '',
  }
  for _, ln in ipairs(drill.after) do
    table.insert(lines, ' │ ' .. ln)
  end
  table.insert(lines, '')
  table.insert(lines, ' \\g grade   \\r reveal   \\R reset   \\s skip   \\n next   \\q quit')
  open_float(lines)
end

local function load_drill_into_buf(buf, drill)
  local before_lines, brow, bcol = strip_cursor(drill.before)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, before_lines)
  vim.bo[buf].modified = false
  pcall(vim.api.nvim_buf_set_name, buf, 'drill://' .. drill.id)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_cursor(win, { brow, bcol })
      vim.api.nvim_set_current_win(win)
    end
  end
  show_text_target(drill)
end

local function open_text_drill(drill)
  close_text_windows()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.cmd('botright vsplit')
  vim.api.nvim_win_set_buf(0, buf)
  session.scratch_buf = buf
  load_drill_into_buf(buf, drill)
end

local function advance_text_drill(drill)
  local buf = session.scratch_buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    load_drill_into_buf(buf, drill)
  else
    open_text_drill(drill)
  end
end

local function build_grade_prompt(drill, observed, orow, ocol)
  local target_lines, trow, tcol = strip_cursor(drill.after)
  local before_lines, brow, bcol = strip_cursor(drill.before)
  return table.concat({
    'You are a Vim drill grader. Reply with ONE LINE of valid JSON. No markdown, no code blocks, no prose.',
    '',
    'DRILL: ' .. drill.id .. '   TAGS: ' .. table.concat(drill.tags, ', '),
    'BEFORE (cursor row ' .. brow .. ' col ' .. bcol .. '):',
    '```', table.concat(before_lines, '\n'), '```',
    'EXPECTED (cursor row ' .. trow .. ' col ' .. tcol .. '):',
    '```', table.concat(target_lines, '\n'), '```',
    'OBSERVED (cursor row ' .. orow .. ' col ' .. ocol .. '):',
    '```', table.concat(observed, '\n'), '```',
    'GOLD-STANDARD KEYSTROKES: ' .. (drill.target or '(unknown)'),
    '',
    'Buffer AND cursor must both match for "matched": true.',
    '',
    'Reply schema:',
    '{',
    '  "matched": <bool>,',
    '  "reason": "<\xe2\x89\xa480 chars: one-line verdict>",',
    '  "explanation": "<\xe2\x89\xa4200 chars: what the user keystrokes did, especially if different from gold>",',
    '  "alternatives": [{"keys": "<sequence>", "when": "<when this is preferable, \xe2\x89\xa460 chars>"}],',
    '  "weak_keys": [<tag>, ...]',
    '}',
    '',
    'Rules for "alternatives":',
    '- Include only if genuinely useful (different mnemonic, more general, fewer keystrokes, semantically different).',
    '- Empty array if the gold-standard is the only sensible approach.',
    '- Max 3 entries.',
  }, '\n')
end

local function show_feedback_float(drill, r)
  local sym = r.matched and '\xe2\x9c\x93 MATCHED' or '\xe2\x9c\x97 NO MATCH'
  local lines = {
    string.format(' %s   %s   (level %d)', drill.id, sym, drill.level or 1),
    '',
  }
  if r.reason and r.reason ~= '' then
    table.insert(lines, ' Reason: ' .. r.reason)
    table.insert(lines, '')
  end
  if r.explanation and r.explanation ~= '' then
    table.insert(lines, ' What you did:')
    for _, l in ipairs(wrap(r.explanation, 60)) do
      table.insert(lines, '   ' .. l)
    end
    table.insert(lines, '')
  end
  if drill.target then
    table.insert(lines, ' Gold: ' .. drill.target)
  end
  if type(r.alternatives) == 'table' and #r.alternatives > 0 then
    table.insert(lines, ' Alternatives:')
    for _, alt in ipairs(r.alternatives) do
      if type(alt) == 'table' and alt.keys then
        local entry = '   \xe2\x80\xa2 ' .. alt.keys
        if alt.when and alt.when ~= '' then entry = entry .. '  \xe2\x86\x92 ' .. alt.when end
        table.insert(lines, entry)
      end
    end
  end
  table.insert(lines, '')
  table.insert(lines, ' \\n next   \\R reset   \\r reveal   \\q quit')
  open_float(lines)
end

local function show_grading_float(drill)
  open_float({
    string.format(' %s   (level %d)', drill.id, drill.level or 1),
    '',
    ' Grading\xe2\x80\xa6  (Claude usually takes 4-7s)',
    '',
    ' \\R reset   \\q quit',
  })
end

local function text_grade()
  local drill = session.current
  local buf = session.scratch_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return vim.notify('Drill scratch buffer is gone', vim.log.levels.ERROR)
  end
  local observed = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cur
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      cur = vim.api.nvim_win_get_cursor(win)
      break
    end
  end
  cur = cur or { 1, 0 }
  show_grading_float(drill)
  vim.system({ 'claude', '-p', build_grade_prompt(drill, observed, cur[1], cur[2]) },
    { text = true }, function(out) vim.schedule(function()
      if out.code ~= 0 then
        return vim.notify('claude failed: ' .. (out.stderr or ''), vim.log.levels.ERROR)
      end
      local ok, r = pcall(vim.json.decode, vim.trim(out.stdout or ''))
      if not ok or type(r) ~= 'table' then
        return vim.notify('Bad JSON:\n' .. (out.stdout or ''), vim.log.levels.ERROR)
      end
      show_feedback_float(drill, r)
      update_state(drill.id, r.matched and 'solved' or 'stuck', r.weak_keys)
      table.insert(session.results, { id = drill.id, matched = r.matched })
    end) end)
end

local function text_reveal()
  local d = session.current
  vim.notify(d.id .. ' target: ' .. (d.target or '(missing)'), vim.log.levels.INFO)
  update_state(d.id, 'stuck', d.tags)
  table.insert(session.results, { id = d.id, matched = false, revealed = true })
end

local function text_reset()
  local buf = session.scratch_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  load_drill_into_buf(buf, session.current)
end

-- ─── Motion mode ───────────────────────────────────────────────────
local function show_motion_prompt(drill)
  close_prompt_window()
  local lines = { string.format(' %s  (level %d)', drill.id, drill.level), '' }
  for _, l in ipairs(wrap(drill.prompt, 60)) do
    table.insert(lines, ' ' .. l)
  end
  table.insert(lines, '')
  table.insert(lines, ' \\g done   \\r reveal   \\s skip   \\n next   \\q quit')
  open_float(lines)
end

local SESSION_KEYS = { 'g', 'r', 'R', 's', 'n', 'q' }

local function set_session_keymaps()
  vim.keymap.set('n', '<localleader>g', M.grade,  { desc = 'Drill: grade/done' })
  vim.keymap.set('n', '<localleader>r', M.reveal, { desc = 'Drill: reveal' })
  vim.keymap.set('n', '<localleader>R', M.reset,  { desc = 'Drill: reset' })
  vim.keymap.set('n', '<localleader>s', M.skip,   { desc = 'Drill: skip' })
  vim.keymap.set('n', '<localleader>n', M.next,   { desc = 'Drill: next' })
  vim.keymap.set('n', '<localleader>q', M.finish, { desc = 'Drill: quit' })
end

local function unset_session_keymaps()
  for _, k in ipairs(SESSION_KEYS) do
    pcall(vim.keymap.del, 'n', '<localleader>' .. k)
  end
end

local function motion_done()
  local d = session.current
  vim.notify('✓ ' .. d.id .. ' done', vim.log.levels.INFO)
  update_state(d.id, 'solved', nil)
  table.insert(session.results, { id = d.id, matched = true })
end

local function motion_reveal()
  local d = session.current
  vim.notify(d.id .. ' target: ' .. (d.target or '(missing)') ..
    '\naccept: ' .. (d.accept or '?'), vim.log.levels.INFO)
  update_state(d.id, 'stuck', d.tags)
  table.insert(session.results, { id = d.id, matched = false, revealed = true })
end

-- ─── Common dispatch ───────────────────────────────────────────────
function M.grade()
  if not session or not session.current then
    return vim.notify('No active drill', vim.log.levels.WARN)
  end
  if session.mode == 'text' then text_grade() else motion_done() end
end

function M.reveal()
  if not session or not session.current then return end
  if session.mode == 'text' then text_reveal() else motion_reveal() end
end

function M.reset()
  if not session or session.mode ~= 'text' then return end
  text_reset()
end

function M.skip()
  if not session then return end
  table.insert(session.results, { id = session.current.id, skipped = true })
  M.next()
end

function M.next()
  if not session then return end
  session.idx = session.idx + 1
  if session.idx > #session.drills then return M.finish() end
  session.current = session.drills[session.idx]
  if session.mode == 'text' then advance_text_drill(session.current)
  else show_motion_prompt(session.current) end
end

function M.finish()
  if not session then return end
  close_prompt_window()
  unset_session_keymaps()
  if session.mode == 'text' then close_text_windows() end
  local solved, total = 0, #session.results
  for _, r in ipairs(session.results) do if r.matched then solved = solved + 1 end end
  vim.notify(string.format('Drill: %d/%d solved', solved, total), vim.log.levels.INFO)
  session = nil
end

function M.text_start(domain)
  local drills = select_text_drills(domain, 5)
  if #drills == 0 then
    return vim.notify('No eligible text drills for: ' .. (domain or 'all'), vim.log.levels.WARN)
  end
  session = { mode = 'text', drills = drills, idx = 1, current = drills[1], results = {} }
  set_session_keymaps()
  open_text_drill(session.current)
end

function M.motion_start(domain)
  local drills = select_motion_drills(domain, 5)
  if #drills == 0 then
    return vim.notify('No eligible motion drills for: ' .. (domain or 'all'), vim.log.levels.WARN)
  end
  session = { mode = 'motion', drills = drills, idx = 1, current = drills[1], results = {} }
  set_session_keymaps()
  show_motion_prompt(session.current)
end

-- ─── Setup ─────────────────────────────────────────────────────────
local TEXT_DOMAINS = { 'motions', 'textobjects', 'operators', 'insert', 'substitute' }
local MOTION_DOMAINS = {
  'hjkl', 'word', 'textobjects', 'operators', 'search', 'marks', 'registers',
  'macros', 'ex', 'folds', 'windows', 'lsp', 'treesitter',
}

function M.setup()
  vim.api.nvim_create_user_command('TextDrill',
    function(o) M.text_start(o.args ~= '' and o.args or nil) end,
    { nargs = '?', complete = function() return TEXT_DOMAINS end })
  vim.api.nvim_create_user_command('Drill',
    function(o) M.motion_start(o.args ~= '' and o.args or nil) end,
    { nargs = '?', complete = function() return MOTION_DOMAINS end })

  vim.api.nvim_create_user_command('DrillGrade',  M.grade,  {})
  vim.api.nvim_create_user_command('DrillReveal', M.reveal, {})
  vim.api.nvim_create_user_command('DrillReset',  M.reset,  {})
  vim.api.nvim_create_user_command('DrillSkip',   M.skip,   {})
  vim.api.nvim_create_user_command('DrillNext',   M.next,   {})
  vim.api.nvim_create_user_command('DrillEnd',    M.finish, {})
end

return M
