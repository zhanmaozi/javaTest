CREATE OR REPLACE PROCEDURE ACT_BIGCOW_EXCHANGE_PRIZE( USERTEL   VARCHAR2, --用户手机号
                                     EXCHANGEFROM VARCHAR2,--兑换来源                                        
                                     PRIZETYPE VARCHAR2, --奖品类型 1.红包，2.电影票
                                     --REDTYPE  VARCHAR2, --红包批次 0 代表电影票   1,2,3,4,5代表红包批次
                                     RETCODE   OUT VARCHAR2,   
                                     --0:成功  1:剩余次数不足, 3:奖品不足 4参数错误  5网络异常                       
                                     ERRMSG    OUT VARCHAR2, --错误信息
                                     PRIZECODE    OUT VARCHAR2) --prizeid
 AS
  V_PRIZETYPE    VARCHAR2(10); --奖品类型
  V_UPDPRIZE_NUM NUMBER; --记录更新奖品行数
  V_CODE         VARCHAR2(255); --prizeid
  V_REDTYPE         VARCHAR2(255); 
BEGIN
  --
  IF USERTEL IS NULL OR TRIM(USERTEL) IS NULL OR
        TRIM(LENGTH(USERTEL)) > 11 OR TRIM(LENGTH(USERTEL)) < 11 THEN
    RETCODE := 4;
    ERRMSG  := '[用户号码]不能为空或需为11位!';
    RETURN;
  ELSIF PRIZETYPE IS NULL OR TRIM(PRIZETYPE) IS NULL OR
        LENGTH(PRIZETYPE) > 1 THEN
    RETCODE := 4;
    ERRMSG  := '[兑换奖品类型]不能为空或超过1位!';
    RETURN;
  END IF;
  --设置参数
  --V_REDTYPE := REDTYPE;
  V_PRIZETYPE := PRIZETYPE;
  V_CODE      := '-1'; --设置初始指-1
  --事务处理，扣除奖品，分配兑奖码，记录中奖记录
  BEGIN
    --扣除次数
    UPDATE GENERAL_SHARE_USER L
       SET L.VALID_COUNT = L.VALID_COUNT - 10
     WHERE      
       (L.VALID_COUNT > 10 or L.VALID_COUNT=10) and L.PHONE_NUMBER = USERTEL;
    V_UPDPRIZE_NUM := SQL%ROWCOUNT;
    IF V_UPDPRIZE_NUM <= 0 THEN
      --扣除奖品失败，则回滚
      ROLLBACK;
      RETCODE := 1;
      ERRMSG  := '剩余次数不足';
      RETURN;
    END IF;
IF V_PRIZETYPE = '1' THEN
        --分配id
    UPDATE GENERAL_EXCHANGE_RESOURCE C
       SET C.EXCHANGE_STATUS = '1'
     WHERE C.ID = (SELECT NVL(MAX(C1.ID), -1)
                     FROM GENERAL_EXCHANGE_RESOURCE C1
                    WHERE C1.EXCHANGE_TYPE = V_PRIZETYPE
                       AND C1.REDTYPE   NOT IN (SELECT t.REDTYPE from GENERAL_EXCHANGE_RECORD t 
                        WHERE t.PHONE_NUMBER = USERTEL AND t.RES_TYPE = V_PRIZETYPE)
                      AND C1.EXCHANGE_STATUS = '0' 
                      )
    RETURNING C.ID,C.REDTYPE INTO V_CODE ,V_REDTYPE;
ELSE
     UPDATE GENERAL_EXCHANGE_RESOURCE C
     SET C.EXCHANGE_STATUS = '1'
     WHERE C.ID = (SELECT NVL(MAX(C1.ID), -1)
                     FROM GENERAL_EXCHANGE_RESOURCE C1
                    WHERE C1.EXCHANGE_TYPE = V_PRIZETYPE 
                                            AND C1.REDTYPE = '0'
                      AND C1.EXCHANGE_STATUS = '0')
    RETURNING C.ID,C.REDTYPE INTO V_CODE ,V_REDTYPE;
 END IF;
    IF V_CODE IS NULL OR V_CODE = '-1' THEN
      ROLLBACK;
      RETCODE := 3;
      PRIZECODE  := V_CODE;
      ERRMSG  := '兑奖码id分配失败，奖品不足';
      RETURN;
    ELSE
      PRIZECODE := V_CODE;
    END IF;
    
    --记录消耗奖品记录
    INSERT INTO GENERAL_EXCHANGE_RECORD
      (PHONE_NUMBER, RES_TYPE, QUANTITY, QUANTITY_DETAIL, 
               EXCHANGE_DATE, CONSUME_QUANTITY, EXCHANGE_FROM,REDTYPE)
    VALUES
      (USERTEL,
       PRIZETYPE,
       1,
       V_CODE,
       SYSDATE,
       10,
       EXCHANGEFROM,V_REDTYPE);
    COMMIT;
    RETCODE := 0; --????
    ERRMSG  := '兑换成功';
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETCODE := 5;
      ERRMSG  := '网络异常';
  END;
  RETURN;
END;