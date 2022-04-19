-- qqquaint           v0.1 by TTQ
--
-- multi-tuning playable quantizer
-- e1 select parameters
-- e2 & e3 change parameters
-- k2 resets
-- grid recommended
--

-- 1. name, 2. steps in oct, 3. ref freq (A4) number
scale = {
  {"12TET", 12, 10, 1, 2^(1/12), 2^(2/12), 2^(3/12), 2^(4/12), 2^(5/12), 2^(6/12), 2^(7/12), 2^(8/12), 2^(9/12), 2^(10/12), 2^(11/12)},
  {"24TET", 24, 19, 1, 2^(1/24), 2^(2/24), 2^(3/24), 2^(4/24), 2^(5/24), 2^(6/24), 2^(7/24), 2^(8/24), 2^(9/24), 2^(10/24), 2^(11/24), 2^(12/24), 2^(13/24), 2^(14/24), 2^(15/24), 2^(16/24), 2^(17/24), 2^(18/24), 2^(19/24), 2^(20/24), 2^(21/24), 2^(22/24), 2^(23/24)},
  {"14EDO", 14, 9, 1/1, 20/19, 11/10, 22/19, 11/9, 9/7, 19/14, 7/5, 28/19, 14/9, 18/11, 19/11, 20/11, 19/10},
  {"24EDO", 24, 19, 1/1, 33/32, 17/16, 12/11, 9/8, 22/19, 19/16, 11/9, 24/19, 22/17, 4/2, 11/8, 17/12, 16/11, 3/2, 17/11, 19/12, 18/11, 32/19, 19/11, 16/9, 11/6, 17/9, 33/17},
  {"Pythagorean", 7, 6, 1/1, 9/8, 81/64, 4/3, 3/2, 27/16, 243/128},
  {"JI", 12, 10, 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 16/9, 15/8},
  {"JI Overtone", 12, 10, 1/1, 17/16, 9/8, 19/16, 5/4, 21/16, 11/8, 3/2, 13/8, 27/16, 7/4, 15/8},
  {"JI Undertone", 12, 10, 1/1, 16/15, 8/7, 32/27, 16/13, 4/3, 16/11, 32/21, 8/5, 32/19, 16/9, 32/17},
  {"JI Zarlino", 16, 13, 1/1, 25/24, 10/9, 9/8, 32/27, 6/5, 4/3, 25/18, 45/32, 3/2, 25/16, 5/3, 16/9, 9/5, 15/8}, --Gioseffo Zarlino's 16-tone
  {"Thirteenten", 9, 7, 1/1, 40/39, 15/13, 13/10, 4/3, 3/2, 20/13, 45/26, 39/20} --Tarkan Grood's 2.3.13/15 scale https://en.xen.wiki/w/Thirteenten
}
params:add_separator("Parameters")
params:add_number("ref_freq_a4", "Reference frequency (A)", 400,500,440)
params:add_number("min_volt", "Minimum cv voltage", 0,5,0)
params:add_number("max_volt", "Maximum cv voltage",1,10,5)
params:add_number("stream_speed","Stream speed",1,100,10)
params:add_number("volts_hysteresis","Input hysteresis",1,100,10)
params:add_number("clock_len","Clock length",1,100,10)
params:add_number("clock_volt","Clock output",1,10,5)

ref_freq_a4 = params:get("ref_freq_a4")

clock_div = {} --set up clock divider
for i=1, 10 do
  clock_div[i] = true
end
volt_memory = {} --set up saving memody
oct_memory = {}
for i=1, 10 do
  volt_memory[i] = 0
  oct_memory[i] = 0
end

note_num = 1
sel_oct = 0

temp = 1 --choosing tempering
transpose = 0
max_transpose = 12
drift = 0
out2_interval = 3
out3_interval = 5
clock_pos = 1
memory_pos = 1
mem_state = false 

page = 0
tune = 1
volts = 0
involts = 1
volts_hysteresis = params:get("volts_hysteresis")/100
outvolts1 = 0
oct = 0


function init()
  create_notes(temp)
  
  crow.input[1].mode("change", 3, 0, "rising")
  crow.input[1].change = change
  crow.input[2].mode("stream",stream_speed)
  crow.input[2].stream = stream
  
  g = grid.connect()
  grid_redraw()
  
  screen.level(8)

end

function stream(v)
  stream_speed = params:get("stream_speed")/1000
  volts_hysteresis = params:get("volts_hysteresis")/100
  min_volt = params:get("min_volt")
  max_volt = params:get("max_volt")
  
  involts = v
  
  involts = util.clamp(involts, min_volt, max_volt)+(transpose*(1/#notes)) --add transpose by dividing volt to number of intervals in scale
  
  tune ="0."..string.sub(involts,3,-1)
  oct = string.sub(involts,1,1)
  
    tune = tune + 0 --convert back to numbers
    oct = oct + 0

  
  --outvolts1 = quantize(tune)
  grid_keys()
  redraw()
end

function change(s)
  clock_len = params:get("clock_len")/100
  clock_volt = params:get("clock_volt")
  
  grid_redraw()
  grid_keys()
  
  state = s
  

  if clock_pos <= 10 then --set up clock
    if clock_div[clock_pos] == true then
      crow.output[4].action = "pulse(clock_len, clock_volt,1)"
      crow.output[4].execute()
    end
    clock_pos = clock_pos +1
  end
  if clock_pos > 10 then 
    clock_pos = 1
  end


-- memory stuff
  if mem_state == false then
    volt_memory[memory_pos] = tune
    oct_memory[memory_pos] = oct
  end
  
  if mem_state == false then
    outvolts1 = quantize(tune)
  end
  
  if mem_state == true then
    outvolts1 = quantize(volt_memory[memory_pos])
    oct = oct_memory[memory_pos]
  end
  
  memory_pos = memory_pos + 1
  if memory_pos > 10 then
    memory_pos = 1
  end
  
  --outputs
  if drift == 0 then
    crow.output[1].volts = outvolts1+oct+sel_oct 
    crow.output[2].volts = outvolts1+oct+sel_oct+(out2_interval*(1/#notes))
    crow.output[3].volts = outvolts1+oct+sel_oct+(out3_interval*(1/#notes))
  else
    crow.output[1].volts = (outvolts1+oct+sel_oct)+(math.random(-10,drift*3)/1000)              
    crow.output[2].volts = (outvolts1+oct+sel_oct)+(out2_interval*(1/#notes))+(math.random(-10,drift*3)/1000) 
    crow.output[3].volts = (outvolts1+oct+sel_oct)+(out3_interval*(1/#notes))+(math.random(-10,drift*3)/1000) 
  end
  
end

function enc(n,d)
  
  if n == 1 then
    page = util.clamp(page + d,0,2)
  end
  
  if n == 2 and page == 0 then
    temp = util.clamp(temp + d,1,#scale)
    create_notes(temp)
  end
  
  if n == 3 and page == 0 then
    drift = util.clamp(drift + d,0,24)
  end

  if n == 2 and page == 1 then
    transpose = util.clamp(transpose + d, 0, max_transpose)
  end
    
  if n == 3 and page == 1 then
    sel_oct = util.clamp(sel_oct + d,-2,2)
  end
  
  if n == 2 and page == 2 then
    out2_interval = util.clamp(out2_interval + d, 1, 7)
  end
  
  if n == 3 and page == 2 then
    out3_interval = util.clamp(out3_interval + d, 1, 7)
  end
  
  grid_redraw()
  
end

function key(n,z)
  if n == 2 and z == 1 then
    transpose = 0
    drift = 0
    sel_oct = 0
  end
end

function redraw()
  
  if page == 0 then
    screen.clear()
    screen.move(10,10)
    screen.level(15)
    screen.text("Scale: "..string.format(scale[temp][1]))
    screen.move(10,20)
    screen.text("Drift: "..(drift))
    screen.move(10,30)
    screen.level(2)
    screen.text("Transpose: "..string.format(transpose))
    screen.move(10,40)
    screen.text("Oct: "..string.format(sel_oct))
    screen.move(10,50)
    screen.level(2)
    screen.text("Out 2 interval: "..string.format(out2_interval))
    screen.move(10,60)
    screen.text("Out 3 interval: "..string.format(out3_interval))
    screen.update()
    screen.update()
  end
  
  if page == 1 then
    screen.clear()
    screen.move(10,10)
    screen.level(2)
    screen.text("Scale: "..string.format(scale[temp][1]))
    screen.move(10,20)
    screen.text("Drift: "..(drift))
    screen.move(10,30)
    screen.level(15)
    screen.text("Transpose: "..string.format(transpose))
    screen.move(10,40)
    screen.text("Oct: "..string.format(sel_oct))
    screen.move(10,50)
    screen.level(2)
    screen.text("Out 2 interval: "..string.format(out2_interval))
    screen.move(10,60)
    screen.text("Out 3 interval: "..string.format(out3_interval))
    screen.update()
  end
  
  if page == 2 then
    screen.clear()
    screen.move(10,10)
    screen.level(2)
    screen.text("Scale: "..string.format(scale[temp][1]))
    screen.move(10,20)
    screen.text("Drift: "..(drift))
    screen.move(10,30)
    screen.level(2)
    screen.text("Transpose: "..string.format(transpose))
    screen.move(10,40)
    screen.text("Oct: "..string.format(sel_oct))
    screen.move(10,50)
    screen.level(15)
    screen.text("Out 2 interval: "..string.format(out2_interval))
    screen.move(10,60)
    screen.text("Out 3 interval: "..string.format(out3_interval))
    screen.update()
    screen.update()
  end
  
end

function grid_keys()
  
 g.key = function(x,y,z)
   if z == 1 then
     
    if x >= 2 and x <= 13 and y >= 2 and y <= 5 then --note selection
      local pressed_note = (x-1)+((y-2)+(((y-2)*11)))
      notes_status[pressed_note] = not notes_status[pressed_note]
    end
    
    if x == 15 and y == 1 then --temp selection
      temp = temp - 1
      temp = util.clamp(temp, 1, #scale)
      create_notes(temp)
    end
    if x == 16 and y == 1 then
      temp = temp + 1
      temp = util.clamp(temp, 1, #scale)
      create_notes(temp)
    end
    
    if y == 7 and x >= 1 and x <= max_transpose+1 then --transpose selection
      transpose = x-1
      
    end
    
    if y == 8 and x >= 1 and x <= 5 then --octave selection
      sel_oct = x-3
    end
    
    if x == 15 and y >= 1 and y <= 8 and y > 1 then --interval input
      out2_interval = 9-y
    end
    if x == 16 and y >= 1 and y <= 8 and y > 1 then --interval input
      out3_interval = 9-y
    end
    
    if x >= 1 and x <= 10 and y == 5 then --clock_div steps
      clock_div[x] = not clock_div[x]
    end
     
    if x == 1 and y == 6 then --switch mem state
      mem_state = not mem_state
    end
    
    if x == 9 and y == 6 then --change drift
      drift = drift - 1
      drift = util.clamp(drift, 0, 24)
    end
    if x == 10 and y == 6 then
      drift = drift + 1
      drift = util.clamp(drift, 0,24)
    end
     
   end

 end
 
  grid_redraw()
end
      

function grid_redraw() --this is horrible code but works
  g:all(0)
  
  g:led(1,1,4) 
  g:led(14,1,4) 
  g:led(1,4,4)
  g:led(14,4,4)
  
  for i=1,max_transpose+1 do --transpose lights
    if i == transpose+1 then
      g:led(i,7,13)
    else
      g:led(i,7,8)
    end
  end
  
  for i=1,5 do --sel_oct lights
    if i == sel_oct+3 then
      g:led(i,8,13)
    else
      g:led(i,8,8)
    end
  end
  
  g:led(15,1,(temp*-1)) --temp lights
  g:led(16,1,(temp+1))
  
  for i=1,out2_interval do --interval2 lights
    g:led(15,9-i,5)
  end
  g:led(15,9-out2_interval,13)
  for i=1,out3_interval do --interval3 lights
    g:led(16,9-i,5)
  end
  g:led(16,9-out3_interval,13)
  
  for i=1,10 do --clock div lights
    if clock_div[i] == true then
      g:led(i,5,10)
    elseif clock_div[i] == false then
      g:led(i,5,4)
    end
  end
  g:led(clock_pos,5,12)
  
  if mem_state == false then --mem lights
    g:led(1,6,5)
  else
    g:led(1,6,12)
  end
  
  if drift >= 0 and drift <= 10 then
    g:led(9,6,10)
    g:led(10,6,4)
  elseif drift > 10 and drift <= 16 then
    g:led(9,6,7)
    g:led(10,6,8)
  elseif drift > 16 then
    g:led(9,6,4)
    g:led(10,6,10)
  end


  
  --note selection below
  if #notes/12 <= 1 then --if it fits on one row
    for i=1, #notes do
      if notes_status[i] == true then
        g:led(i+1,2,10)
      else
        g:led(i+1,2,5)
      end
    end
    g:led(note_num+1,2,15)
  end
  
  if #notes/12 > 1 and #notes%12 == 0 then
    for i=1, 12 do
      if notes_status[i] == true then
        g:led(i+1,2,10)
      else
        g:led(i+1,2,5)
      end
    end
    for i=1,#notes-12 do
      if notes_status[i+12] == true then
        g:led(i+1,3,10)
      else
        g:led(i+1,3,5)
      end
    end
    if note_num <= 12 then
      g:led(note_num+1,2,15)
    elseif note_num > 12 then
      g:led((note_num-12)+1,3,15)
    end
  end
  
  if #notes/12 > 1 and #notes%12 ~= 0 then
    for i=1, 12 do
      if notes_status[i] == true then
        g:led(i+1,2,10)
      else
        g:led(i+1,2,5)
      end
    end
    for i=1,#notes-12 do
      if notes_status[i+12] == true then
        g:led(i+1,3,10)
      else
        g:led(i+1,3,5)
      end
    end
    
    if note_num <= 12 then
      g:led(note_num+1,2,15)
    elseif note_num > 12 then
      g:led((note_num-12)+1,3,15)
    end
  end
  --note selection ends
  
  g:refresh()
  
end
  
  
function create_notes(temp) --what tempering is used
  
  notes = {}
  notes_status = {}
  
  ref_freq_a4 = params:get("ref_freq_a4")
  
  ref_freq_c4 = ref_freq_a4/scale[temp][scale[temp][3]+3]
  for i=1, scale[temp][2] do
    notes[i]=ref_freq_c4*scale[temp][(i+3)]
    notes_status[i]=true
  end
  
  max_transpose = #notes
  max_transpose = util.clamp(max_transpose, 0, 13)
  
end

function quantize(volts)
  
  local diff = 0.1
  note_num = 1

  
  for i=1,#notes do
    if math.abs(volts-(i/#notes)) < diff and notes_status[i] == true then
      note_num = i
    end
  end

  
  if volts <= volts_hysteresis then
    note_num = 1
  end
  
  
  note_num = util.clamp(note_num,1,#notes)
  
  note_volt = math.log(notes[note_num]/ref_freq_c4)/math.log(2)
  
  return note_volt

end
