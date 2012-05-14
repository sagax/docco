$ ->
  bars = $('.code_stats span[data-lang][percent]')
  return unless bars.length
  start_index = bars.length - 1

  do animate = ->
    bar = $ bars[start_index--]
    return unless bar.length
    bar.animate {width: bar.attr('percent')}, 600, animate
