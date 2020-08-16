#!/bin/sh

timer_work=1500
timer_break=300
timer_long_break=900

icon_stopped=""
icon_started=""
icon_paused=""
icon_break=""
icon_long_break=""

clr_paused=de935f
clr_started=689d6a
clr_stopped=cc241d

pipe=/tmp/pomodoro.pipe
mkfifo -m 0600 $pipe
trap "trap - SIGTERM && rm -f $pipe && kill -- -$$" SIGINT SIGTERM EXIT

main() {
  reset
  while true ; do
    sleep 1 &
    wait
    echo ping > $pipe
  done &

  while read pipe ; do
    case "$pipe" in
      ping) [[ $status =~ work|break|long_break ]] && ((paused == 0)) && ((timer--)) ; status ;;
      toggle) toggle ;;
      reset)  reset ;;
      notify) notify status ;;
    esac
  done < $pipe 3> $pipe
}

status() {

  set_timer

  case $status in
    work|break|long_break) 
      if ((paused)) ; then
        underline=$clr_paused 
        icon=$icon_paused
      else
        underline=$clr_started 
        case $status in
          work)       icon=$icon_started ;;
          break)      icon=$icon_break ;;
          long_break) icon=$icon_long_break ;;
        esac
      fi
      ;;
    stopped) 
      underline=$clr_stopped
      icon=$icon_stopped
      echo %{u#${underline}} $icon %{-u} 
      return
      ;;
  esac

  minutes=0$((timer / 60))
  seconds=0$((timer % 60)) 
  remaining=${minutes: -2}:${seconds: -2}

  echo %{u#${underline}}$icon $remaining%{-u}
}

toggle() {
  case $status in
    work|break|long_break) ((paused=(++paused % 2))) ;;
    stopped) status=work ;;
  esac
  status
}

set_timer() {
  if [[ $status != "stopped" ]] ; then
    if ((${timer:=$timer_work} < 0)) ; then
      if (($i % 9 == 0)) ; then
        status=long_break
        timer=$timer_long_break
        i=1
      elif (($i % 2 == 0)) ; then
        status=work
        timer=$timer_work
      else
        status=break
        timer=$timer_break
      fi
      ((i++))
    fi
  else
    timer=$timer_work
  fi
}

reset() {
  status=stopped
  paused=0
  i=3
  set_timer
  status
}

notify() {
  case $1 in
    status) 
      case $status in
        work) notify-send "Pomodoro Timer" "Get to work!\n\nTime remaining: $remaining" ;;
        break) notify-send "Pomodoro Timer" "Enjoy a short break\n\nTime remaining: $remaining" ;;
        long_break) notify-send "Pomodoro Timer" "Enjoy a long break\n\nTime remaining: $remaining" ;;
      esac
  esac
}

main $*
