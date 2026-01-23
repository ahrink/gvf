#include <stdio.h>
#include <string.h>
#include <time.h>

// Function to auto-generated tID ala AHR for instantiating
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

void seg_stamp(const char* stamp, char* s_date, char* s_time, char* s_nano) {
  // Extract date (YYYYMMDD)
  strncpy(s_date, stamp, 8);
  s_date[8] = '\0';

  // Extract time (hhmmss)
  strncpy(s_time, stamp + 8, 6);
  s_time[6] = '\0';

  // Extract nanoseconds part or segment
  strncpy(s_nano, stamp + 14, 9);  // Copy only 9 digits
  s_nano[9] = '\0'; // Ensure null termination
}


int main() {
  char tID[24];
  char s_date[9], s_time[7], s_nano[10]; // Adjust size to accommodate "."

  // Generate AHR timestamp instance
  char* stamp = ahr(1);  // Assuming ahr function can also be defined elsewhere

  // compute for final output
  seg_stamp(stamp, s_date, s_time, s_nano);

  // Print elements with leading "." for nanoseconds interpretation as a decimal value
  printf("%s|%s|.%s\n", s_date, s_time, s_nano); // segmentation
  printf("%s\n", stamp); // compare with injected stamp

  return 0;
}
