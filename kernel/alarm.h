#ifndef ALARM_H_BED
#define ALARM_H_BED

// returns 0 if failed or already exists
extern int set_alarm(int ,void*);

// getting status
extern int get_is_alarm_set();
extern int get_end_tick();

// calling handler when its time (forking involved)
extern int run_alarm_handler();

//reset alarm
extern int reset_alarm();

#endif