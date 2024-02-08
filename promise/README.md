# Бенчмарки производительности блокировок аля Promise


## Запуск

```shell
./bm.rb
```

Потом в соседней владке меняем (нужет root) приоритет если есть желание

```shell
sudo renice -n -20 -p ПИД-КОТОРЫЙ-ПЕЧАТАЕТСЯ-ПРИ-СТАРТЕ

```

## Результаты

### ruby 2.7.2

```shell
    ===== [24176] Benchmark[RUBY=2.7.2 THREADS=10 COUNT=900000] YJIT=false] =====
                                 user     system      total         real
            Promises::Queue  3.121730   3.221712   6.343442 (  4.558971)   197413.0 ips
Promises::ConditionVariable  2.987070   2.056038   5.043108 (  5.046945)   178325.7 ips
           Promises::Thread  4.577287   3.550643   8.127930 (  5.685244)   158304.6 ips
           Promises::Socket  7.508728   8.266008  15.774736 ( 11.249557)   80003.1 ips
   Promises::ConcurrentRuby 11.318772   2.435386  13.754158 ( 12.390275)   72637.6 ips
```


### ruby 3.3.0

```shell
    ===== [24751] Benchmark[RUBY=3.3.0 THREADS=10 COUNT=900000] YJIT=false] =====
                                 user     system      total         real
            Promises::Queue  2.447489   1.029832   3.477321 (  3.903307)   230573.7 ips
Promises::ConditionVariable  2.846387   1.014867   3.861254 (  4.290477)   209766.9 ips
           Promises::Thread  3.628851   0.978113   4.606964 (  5.029280)   178952.0 ips
           Promises::Socket  7.181029   6.640103  13.821132 ( 12.131390)   74187.7 ips
   Promises::ConcurrentRuby 10.174657   1.061579  11.236236 ( 11.740545)   76657.4 ips
```

### ruby 3.3.0 YJIT

```shell
    ===== [25251] Benchmark[RUBY=3.3.0 THREADS=10 COUNT=900000] YJIT=true] =====
                                 user     system      total         real
            Promises::Queue  2.423679   0.973922   3.397601 (  3.827920)   235114.6 ips
Promises::ConditionVariable  2.497772   0.995617   3.493389 (  3.911033)   230118.2 ips
           Promises::Thread  2.960896   1.043621   4.004517 (  4.438562)   202768.4 ips
           Promises::Socket  7.019178   6.942759  13.961937 ( 11.901253)   75622.3 ips
   Promises::ConcurrentRuby  5.557667   1.094702   6.652369 (  7.088907)   126958.9 ips
```
