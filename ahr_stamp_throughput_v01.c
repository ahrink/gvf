#include <stdio.h>
#include <time.h>

// Function to auto-generate tID ala AHR for instantiating
char* ahr(int instance) {
    static char tID[24]; // Static variable to hold the 23-character tID

    struct timespec currentTime;
    clock_gettime(CLOCK_REALTIME, &currentTime);

    struct tm timeInfo;
    localtime_r(&currentTime.tv_sec, &timeInfo);

    snprintf(tID, sizeof(tID), "%04d%02d%02d%02d%02d%02d%09ld",
             timeInfo.tm_year + 1900,
             timeInfo.tm_mon + 1,
             timeInfo.tm_mday,
             timeInfo.tm_hour,
             timeInfo.tm_min,
             timeInfo.tm_sec,
             currentTime.tv_nsec);

    return tID;
}

int main() {
    int max_loops = 1000000; // Change this value to control the number of loops
    int counter = 1;
    struct timespec start, end;

    clock_gettime(CLOCK_REALTIME, &start);

    // Loop execution
    while (counter <= max_loops) {
        // Call the ahr function to generate tID
        char *tID = ahr(counter); // Pass instance number if needed

        // Uncomment this if you want to print the results
        // printf("%d. %s\n", counter, tID);

        // Increment the counter
        counter++;
    }

    clock_gettime(CLOCK_REALTIME, &end);

    double elapsed_time = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("Elapsed time: %.9f seconds\n", elapsed_time);
    printf("Average iterations per second: %.2f\n", max_loops / elapsed_time);

    return 0;
}
