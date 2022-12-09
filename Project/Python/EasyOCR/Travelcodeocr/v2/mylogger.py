import os
import logging
from logging.handlers import TimedRotatingFileHandler

LOG_PATH = "log"
LOG_INFO = '_info.log'
LOG_ERROR = '_error.log'

class logger:
  def __init__(self, prefix_name = "flask"):
    if (not os.path.exists(LOG_PATH)):
      os.makedirs(LOG_PATH)

    self.prefix = prefix_name

    # 创建logger日志对象
    self.info_logger = logging.getLogger("info")
    self.error_logger = logging.getLogger("error")

    # 日志的最低输出级别
    self.info_logger.setLevel(logging.DEBUG)
    self.error_logger.setLevel(logging.ERROR)

    # 日志格式化
    self.format = logging.Formatter('[%(asctime)s][%(threadName)s:%(thread)d][task_id:%(name)s][%(filename)s:%(lineno)d]' '[%(levelname)s] : %(message)s')
    
    # 按照时间切割文件 Handler 配置
    TimeFileHandlerINFO = TimedRotatingFileHandler("%s/%s%s" % (LOG_PATH, prefix_name, LOG_INFO), when='MIDNIGHT', encoding="utf-8", backupCount=8760, delay=True)
    TimeFileHandlerINFO.suffix = "%Y-%m-%d.log"
    TimeFileHandlerERROR = TimedRotatingFileHandler("%s/%s%s" % (LOG_PATH, prefix_name, LOG_ERROR), when='MIDNIGHT', encoding="utf-8", backupCount=8760, delay=True)
    TimeFileHandlerERROR.suffix = "%Y-%m-%d.log"
    LoggerStream = logging.StreamHandler()
    
    # 设置日志格式化
    TimeFileHandlerINFO.setFormatter(self.format)
    TimeFileHandlerERROR.setFormatter(self.format)
    LoggerStream.setFormatter(self.format)

    # 添加设置的句柄
    self.info_logger.addHandler(TimeFileHandlerINFO)
    # self.info_logger.addHandler(LoggerStream)
    self.error_logger.addHandler(TimeFileHandlerERROR)
    # self.error_logger.addHandler(LoggerStream)

  def debug(self, msg, *args, **kwargs):
    self.info_logger.debug(msg, *args, **kwargs)

  def info(self, msg, *args, **kwargs):
    self.info_logger.info(msg, *args, **kwargs)

  def warn(self, msg, *args, **kwargs):
    self.info_logger.warning(msg, *args, **kwargs)

  def error(self, msg, *args, **kwargs):
    self.error_logger.error(msg, *args, **kwargs)

  def fatal(self, msg, *args, **kwargs):
    self.error_logger.fatal(msg, *args, **kwargs)

  def critical(self, msg, *args, **kwargs):
    self.error_logger.critical(msg, *args, **kwargs)