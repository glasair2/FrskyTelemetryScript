--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
---------------------
-- GLOBAL DEFINES
---------------------
--#define X9
--#define 
-- always use loadscript() instead of loadfile()
-- force a loadscript() on init() to compile all .lua in .luac
--#define COMPILE
---------------------
-- VERSION
---------------------
---------------------
-- FEATURES
---------------------
--#define BATTMAH3DEC
-- enable altitude/distance monitor and vocal alert (experimental)
--#define MONITOR
-- show incoming DIY packet rates
--#define TELEMETRY_STATS
-- enable synthetic vspeed when ekf is disabled
--#define SYNTHVSPEED
-- enable telemetry reset on timer 3 reset
-- always calculate FNV hash and play sound msg_<hash>.wav
-- enable telemetry logging menu option
--#define LOGTELEMETRY
-- enable max HDOP alert 
--#define HDOP_ALARM
-- enable support for custom background functions
--#define CUSTOM_BG_CALL
-- enable alert window for no telemetry
--#define NOTELEM_ALERT
-- enable popups for no telemetry data
--#define NOTELEM_POPUP
-- enable blinking rectangle on no telemetry
---------------------
-- DEBUG
---------------------
--#define DEBUG
--#define DEBUGEVT
--#define DEV
--#define MEMDEBUG
-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
---------------------
-- TESTMODE
---------------------
-- enable script testing via radio sticks
--#define TESTMODE


---------------------
-- SENSORS
---------------------












-- Throttle and RC use RPM sensor IDs





------------------------
-- MIN MAX
------------------------
-- min

------------------------
-- LAYOUT
------------------------
  










--#define HOMEDIR_X 42




--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]


-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"



-----------------------
-- HUD AND YAW
-----------------------
-- vertical distance between roll horiz segments

-- vertical distance between roll horiz segments
-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1



-- X-Lite Support

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------














---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- GPS status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  lcd.drawLine(x,6 + 20,1+30,6 + 20,SOLID,FORCE)
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(x+1, 6+13, strStatus, SMLSIZE)
    local strNumSats
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+1 + 29, 6 + 13, strNumSats, SMLSIZE+RIGHT)
    lcd.drawText(x+1, 6 + 2 , "Hd", SMLSIZE)
    lcd.drawNumber(x+1 + 29, 6+1, telemetry.gpsHdopC*mult ,MIDSIZE+flags+RIGHT)
    
  else
    lcd.drawText(x+1 + 8, 6+3, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(x+1 + 5, 6+12, strStatus, SMLSIZE+INVERS+BLINK)
  end
  -- alt asl/rng
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
    flags = 0
  if conf.rangeFinderMax > 0 then
    -- rng finder
    local rng = telemetry.range
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
      -- update max only with 3d or better lock
    rng = getMaxValue(rng,16)
    lcd.drawText(x+31, 30+1 , unitLabel, SMLSIZE+RIGHT)
    
    if rng*unitScale*0.01 > 10 then
      lcd.drawNumber(lcd.getLastLeftPos(), 30, rng*unitScale*0.1, flags+RIGHT+SMLSIZE+PREC1)
    else
      lcd.drawNumber(lcd.getLastLeftPos(), 30, rng*unitScale, flags+RIGHT+SMLSIZE+PREC2)
    end
    
    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+1+1, 30,5,true,false)
    else
      lcd.drawText(x+1, 30, "R", SMLSIZE)
    end
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,12)
    end
    lcd.drawText(x+31, 30,unitLabel, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), 30, alt*unitScale, flags+RIGHT+SMLSIZE)
    
    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+1+1, 30 + 1,5,true,false)
    else
      drawLib.drawVArrow(x+1+1,30,5,true,true)
    end
  end
  -- home dist
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+31, 40, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 40, dist*unitScale,SMLSIZE+RIGHT+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+1+1, 42-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+1, 42)
  end
  -- total distance
  lcd.drawText(32, 50, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), 50, telemetry.totalDist*unitLongScale*10, RIGHT+SMLSIZE+PREC1)  
end


return {
  drawPane=drawPane,
}
