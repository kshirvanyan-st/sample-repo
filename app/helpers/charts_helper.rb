# Small server-rendered SVG charts for the admin dashboards (no JS charting library).
# Mark specs: single series in --viz-series-1, bars with 4px rounded tops anchored on the
# baseline, 2px gaps, recessive grid, hover tooltip on every bar, and a table view.
module ChartsHelper
  CHART_HEIGHT = 180
  TOP_PADDING = 12 # room for the top tick label
  AXIS_WIDTH = 56
  LABEL_HEIGHT = 20

  # Vertical bars over time. points: [[label, value], ...]; format: ->(value) { "..." }
  def bar_chart(points, title:, format: ->(v) { number_with_delimiter(v) })
    width = 720
    plot_width = width - AXIS_WIDTH
    max = [ points.map(&:last).max.to_f, 1 ].max
    ticks = nice_ticks(max)
    top = ticks.last.to_f
    slot = plot_width / [ points.size, 1 ].max.to_f
    bar = [ slot - 2, 1 ].max # 2px gap between adjacent bars
    y = ->(value) { CHART_HEIGHT - (value / top * CHART_HEIGHT) }

    grid = ticks.map do |tick|
      tag.line(x1: AXIS_WIDTH, x2: width, y1: y.(tick), y2: y.(tick), class: "viz-grid") +
        tag.text(format.(tick), x: AXIS_WIDTH - 8, y: y.(tick) + 4, "text-anchor": "end", class: "viz-axis")
    end

    every = (points.size / 6.0).ceil
    bars = points.each_with_index.map do |(label, value), i|
      x = AXIS_WIDTH + i * slot + 1
      height = CHART_HEIGHT - y.(value)
      mark = height.positive? ? tag.path(d: rounded_top_bar(x, y.(value), bar, height), class: "viz-bar") : "".html_safe
      tag.g(class: "viz-hit") do
        tag.title("#{label}: #{format.(value)}") +
          tag.rect(x: x - 1, y: 0, width: slot, height: CHART_HEIGHT, fill: "transparent") + mark +
          ((i % every).zero? ? tag.text(label, x: x + bar / 2, y: CHART_HEIGHT + 15, "text-anchor": "middle", class: "viz-axis") : "".html_safe)
      end
    end

    tag.figure(class: "viz-root") do
      tag.svg(viewBox: "0 -#{TOP_PADDING} #{width} #{CHART_HEIGHT + LABEL_HEIGHT + TOP_PADDING}", role: "img", "aria-label": title, class: "w-full h-auto") do
        safe_join(grid) + tag.line(x1: AXIS_WIDTH, x2: width, y1: CHART_HEIGHT, y2: CHART_HEIGHT, class: "viz-baseline") + safe_join(bars)
      end + data_table(points, format)
    end
  end

  # Horizontal bars for ordered steps (a funnel), each labeled with its value.
  def step_bars(steps)
    max = [ steps.map { |s| s[:users] }.max.to_i, 1 ].max
    tag.div(class: "space-y-2 viz-root") do
      safe_join(steps.map do |step|
        tag.div(title: "#{step[:step]}: #{number_with_delimiter(step[:users])} (#{number_to_percentage(step[:share] * 100, precision: 0)})") do
          tag.div(class: "flex justify-between text-sm") do
            tag.span(step[:step], class: "viz-text") +
              tag.span("#{number_with_delimiter(step[:users])} · #{number_to_percentage(step[:share] * 100, precision: 0)}", class: "viz-text-secondary tabular-nums")
          end +
            tag.div(class: "h-3 rounded viz-track") { tag.div(class: "h-3 rounded viz-fill", style: "width: #{(step[:users] * 100.0 / max).round(1)}%") }
        end
      end)
    end
  end

  # Background for a retention heatmap cell: sequential blue, light (low) to dark (high).
  # Steps 250..650 of the reference blue ramp (validated as an ordinal ramp on white:
  # the light end clears 2:1). Values are printed in every cell, so color is never alone.
  RETENTION_STEPS = [ [ 0.05, "#86b6ef", "#0b0b0b" ], [ 0.15, "#5598e7", "#0b0b0b" ], [ 0.3, "#2a78d6", "#ffffff" ], [ 0.5, "#1c5cab", "#ffffff" ], [ 1.01, "#104281", "#ffffff" ] ].freeze

  def retention_cell(share)
    return tag.td("–", class: "p-2 text-center viz-text-muted") if share.nil?

    _, background, ink = RETENTION_STEPS.find { |limit, _, _| share < limit }
    tag.td(number_to_percentage(share * 100, precision: 0), class: "p-2 text-center tabular-nums", style: "background: #{background}; color: #{ink}")
  end

  private
    # A bar whose top corners are rounded (4px) and whose bottom sits square on the baseline.
    def rounded_top_bar(x, top, width, height)
      r = [ 4, width / 2, height ].min
      "M#{x},#{top + height} V#{top + r} Q#{x},#{top} #{x + r},#{top} H#{x + width - r} Q#{x + width},#{top} #{x + width},#{top + r} V#{top + height} Z"
    end

    def nice_ticks(max)
      raw = max / 4.0
      magnitude = 10**Math.log10(raw).floor
      step = [ 1, 2, 2.5, 5, 10 ].map { |m| m * magnitude }.find { |s| s >= raw }
      (0..4).map { |i| (i * step).round(6) }
    end

    def data_table(points, format)
      tag.details(class: "mt-2 text-sm") do
        tag.summary("Show as table", class: "cursor-pointer viz-text-secondary") +
          tag.table(class: "mt-2 w-full") do
            safe_join(points.map { |label, value| tag.tr { tag.td(label, class: "py-0.5") + tag.td(format.(value), class: "py-0.5 text-right tabular-nums") } })
          end
      end
    end
end
