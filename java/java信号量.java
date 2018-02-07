package com.XXXXXX;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

/**
 * Created by maxiaoying on 2018/2/2.
 * DESC:线程信号量demo
 
  问题背景：
  公司的微信公众号用户量比较大，每个月月初的时候会给用户推送上个月的账单数据，除此之外还会不定期给用户推送一些营销活动的模板消息。
  当前的解决办法是：
  抽取用户数据后将用户分组标记，分为10个组，然后开启10个线程，一个线程一个组，互不相干。至此一小时推送7W左右。
  业务希望能提高速度，于是改进办法：
  采用newCachedThreadPool线程池，结果是速度快了，因为推送的tomcat和主项目公用一台服务器，用了线程池之后，速度提高了但是影响了主项目的响应速度，于是放弃
  天无绝人之路，重在思考。
  发现java有信号量，可以控制资源，于是把线程当资源，控制并发线程数，这样一来的话就
 
 
 
 */
public class SemaphoreDemo {
    public static void main(String[] args) {
        // 线程池
        ExecutorService exec = Executors.newCachedThreadPool();        
        int sempNum=5;
        //控制5个共享资源的使用，使用先进先出的公平模式进行共享;公平模式的信号量，先来的先获得信号量
        Semaphore semp = new java.util.concurrent.Semaphore(sempNum,true);
        //当前还可通行线程数
        int availablePermits=semp.availablePermits();
        //前作用的队列长度
        int queueLength=semp.getQueueLength();
        //当前是否有线程等待进入队列
        boolean hasQueuedThreads=semp.hasQueuedThreads();                      
        Semaphore semp = new java.util.concurrent.Semaphore(5,true);    
        //每次查询100条数据
        List<Map<String, Object>> list = XXXXXXXXXX;
        if (list!=null){
            int len=list.size();
            if (len>0){
                while (len>0){
                    // 模拟50个客户端访问
                    for (int index = 0; index < len; index++) {
                        final int NO = index;
                        Runnable run = new Runnable() {
                            public void run() {
                                try {
                                    // 获取许可
                                    semp.acquire();
                                    System.out.println("Accessing: " + NO);
                                    Thread.sleep((long) (Math.random() * 6000));
                                    System.out.println(NO+"===>>>"+semp.getQueueLength());
                                    // 访问完后，释放
                                    semp.release();
                                    //availablePermits()指的是当前信号灯库中有多少个可以被使用
                                    System.out.println("-----------------" + semp.availablePermits());
                                } catch (InterruptedException e) {
                                    e.printStackTrace();
                                }
                            }
                        };
                        executorPool.execute(run);
                    }
                    //等待上面的线程执行完毕
                    if (!hasQueuedThreads  && availablePermits==sempNum && queueLength==0){
                        System.out.println("==========第二轮");
                        if (PushConfig.isPush()){
                            list =XXXXXXXXXXXXXX;
                            len=list.size();
                        }else {
                            return;
                        }
                    }
                }
            }
        }else {
            logger.info("查询list="+list);
        }
    }




}
