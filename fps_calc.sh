#!/bin/sh
# fps_calc.sh frames per second transition =(case/60)/A4
# Constants for time measurements
A1=1000000000  # nanoseconds (n) Latin
A2=1000000     # microseconds (μ) U+03BC Greek
A3=1000        # milliseconds (m) Latin

# Prompt user for frames per second input
echo "Enter frames per second (fps):"
read A4

# Check if A4 is a valid number
if ! echo "$A4" | grep -qE '^[0-9]+$'; then
    echo "Invalid input. Please enter a valid number for frames per second."
    exit 1
fi

# Calculate duration per frame for milliseconds ms
duration_ms=$(echo "$A3 / 60 / $A4" | bc -l)
echo "Duration per frame (milliseconds ms): $duration_ms seconds/frame"

# Calculate duration per frame for microseconds μs
duration_us=$(echo "$A2 / 60 / $A4" | bc -l)
echo "Duration per frame (microseconds μs): $duration_us seconds/frame"

# Calculate duration per frame for nanoseconds ns
duration_ns=$(echo "$A1 / 60 / $A4" | bc -l)
echo "Duration per frame (nanoseconds ns): $duration_ns seconds/frame"

# Happy stepping through the wheels of time
keywords: #elapses, #rotation, #touring, #stepping
