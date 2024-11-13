// rollover_remover.mq5
// Author: Greg Kaye

#property strict

#include <Trade\Trade.mqh>

// Declare a dynamic array to store stop levels
double stops[];
bool stopsRemoved = false;
datetime startTime, endTime;

// Inputs for user-specified start and end times
input int startHour = 23;   // Start hour (24-hour format)
input int startMinute = 21; // Start minute
input int endHour = 23;     // End hour (24-hour format)
input int endMinute = 23;   // End minute

input int timerInterval = 1;     // Timer interval in seconds
input int maxCloseAttempts = 20; // Timer interval in seconds

void CloseTrade(ulong ticket)
{
    for (int attempt = 1; attempt <= maxCloseAttempts; attempt++)
    {
        Print("Position out of bounds.  Attempting to close position: " + ticket + " (Attempt #: " + attempt + ")");
        if (PositionSelectByTicket(ticket))
        {
            CTrade m_trade;
            if (m_trade.PositionClose(ticket))
            {
                Print("Position closed successfully: " + PositionGetString(POSITION_SYMBOL) + " " + ticket);
                return;
            }
            else
            {
                Print("Error closing position: " + ticket);
                Print("Error: ", GetLastError());
            }
        }
        else
        {
            Print("Error closing position: " + ticket);
            Print("Error: ", GetLastError());
        }

        Sleep(100);
    }

    Print("ERROR: USER INTERVENTION REQUIRED! Could not terminate out of bounds position " + ticket);
}

// Function to remove stop levels from all open orders
void RemoveStops()
{
    int totalOrders = PositionsTotal();
    ArrayResize(stops, totalOrders);

    for (int i = ArraySize(stops) - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                // Store current stop loss level
                stops[i] = PositionGetDouble(POSITION_SL);

                if (stops[i] == 0)
                {
                    Print("Skipping removing stop for order " + PositionGetString(POSITION_SYMBOL) + " " + ticket + " because no stop loss is set.");
                    continue;
                }

                Print("Removing stop for order " + PositionGetString(POSITION_SYMBOL) + " " + ticket + " @ " + stops[i]);

                // Remove stop loss level
                MqlTradeRequest request;
                MqlTradeResult result;
                ZeroMemory(request);
                request.action = TRADE_ACTION_SLTP;
                request.position = ticket;
                request.sl = 0; // Remove stop loss
                request.tp = PositionGetDouble(POSITION_TP);

                if (!OrderSend(request, result))
                {
                    Print("Error removing stop loss: ", GetLastError());
                }
            }
        }
    }
}

// Function to restore stop levels to all open orders
void RestoreStops()
{
    for (int i = ArraySize(stops) - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            if ((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL))
            {
                if (stops[i] == 0)
                {
                    Print("Skipping restoring stop for order " + PositionGetString(POSITION_SYMBOL) + " " + ticket + " because no stop loss was previously set.");
                    continue;
                }

                Print("Restoring stop for order " + PositionGetString(POSITION_SYMBOL) + " " + ticket + " @ " + stops[i]);

                double currentPrice = 0;
                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                {
                    currentPrice = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_BID); // Current market price for buy orders
                    if (stops[i] >= currentPrice)
                    {
                        CloseTrade(ticket);

                        continue;
                    }
                }
                else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                {
                    currentPrice = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_ASK); // Current market price for sell orders
                    if (stops[i] <= currentPrice)
                    {
                        CloseTrade(ticket);

                        continue;
                    }
                }

                // Restore stop loss level if the above conditions are not met
                MqlTradeRequest request;
                MqlTradeResult result;
                ZeroMemory(request);
                request.action = TRADE_ACTION_SLTP;
                request.position = ticket;
                request.sl = stops[i]; // Restore stop loss
                request.tp = PositionGetDouble(POSITION_TP);

                if (!OrderSend(request, result))
                {
                    Print("Error restoring stop loss: ", GetLastError());
                }
            }
        }
    }
}

// Function to calculate start and end times based on user input
void CalculateTimes()
{
    datetime currentDate = TimeCurrent();
    startTime = StringToTime(TimeToString(currentDate, TIME_DATE) + " " + IntegerToString(startHour) + ":" + IntegerToString(startMinute) + ":00");
    endTime = StringToTime(TimeToString(currentDate, TIME_DATE) + " " + IntegerToString(endHour) + ":" + IntegerToString(endMinute) + ":00");
}

// Expert initialization function
int OnInit()
{
    // Set timer based on user-specified interval
    EventSetTimer(timerInterval);

    return INIT_SUCCEEDED;
}

// Expert deinitialization function
void OnDeinit(const int reason)
{
    EventKillTimer();
}

// Timer function
void OnTimer()
{
    // Calculate start and end times based on user input
    CalculateTimes();

    datetime currentTime = TimeCurrent();
    Print("Server time: " + currentTime);

    // Remove stops if within specified time period
    if (currentTime >= startTime && currentTime < endTime)
    {
        if (!stopsRemoved)
        {
            RemoveStops();
            stopsRemoved = true;
        }
    }
    // Restore stops after the specified time period elapses
    else if (currentTime >= endTime)
    {
        if (stopsRemoved)
        {
            RestoreStops();
            stopsRemoved = false;
        }
    }
}
