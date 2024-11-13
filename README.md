# Rollover Remover Plugin

The Rollover Remover Plugin for MetaTrader 5 addresses the issue of temporary volatility spikes during the daily forex rollover period, which can increase spreads and result in stop losses being prematurely triggered. This plugin helps prevent unnecessary stop-out events by temporarily disabling stop losses during the rollover period.

Used by professional traders, this plugin ensures that your trades are not adversely affected by volatility during daily rollover events.

## Configuration

To set your desired rollover removal time window, edit the following parameters within the script:

- `startHour`: The hour at which stop losses should be temporarily removed.
- `startMinute`: The minute at which stop losses should be temporarily removed.
- `endHour`: The hour at which stop losses should be restored.
- `endMinute`: The minute at which stop losses should be restored.

The script uses the server's time to determine the rollover window. To ensure accuracy, check the logs and compare the desired time to the `"Server time:"` log message to normalize against your local timezone.

## Installation

1. Download the plugin.
2. Place the script in your MetaTrader 5 `Expert Advisors` folder.
3. Compile and run the script in your MetaTrader 5 platform.
4. Adjust the configuration parameters (Mentioned in the configuration section) as needed.

## Disclaimer

This plugin is intended to assist with managing volatility during rollover periods but does not guarantee the prevention of all adverse trading outcomes. Use it at your own risk and ensure it fits your trading strategy.
