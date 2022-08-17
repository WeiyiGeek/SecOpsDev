// https://blog.weiyigeek.top

const fs = require('fs');
const path = require('path');
const url = require('url');

const request = require('request');
const xmlParser = require('xml-parser');
const md5 = require('md5');
const { exit } = require('process');

let wait = ms => new Promise(resolve => setTimeout(resolve, ms));


// 配置信息
const config = {
  username: 'weiyigeek', // GitHub repository 所有者，可以是个人或者组织。对应Gitalk配置中的owner
  repo: "blogtalk", // 储存评论issue的github仓库名，仅需要仓库名字即可。对应 Gitalk配置中的repo
  token: '<此处你需要自己在Github生成私有认证Token>', // 前面申请的 personal access token
  sitemap: path.join(__dirname, './public/sitemap.xml'), // 自己站点的 sitemap 文件地址
  cache: true, // 是否启用缓存，启用缓存会将已经初始化的数据写入配置的 gitalkCacheFile 文件，下一次直接通过缓存文件判断
  gitalkCacheFile: path.join(__dirname, './gitalk-init-cache.json'), // 用于保存 gitalk 已经初始化的 id 列表
  gitalkErrorFile: path.join(__dirname, './gitalk-init-error.json'), // 用于保存 gitalk 初始化报错的数据
};

const api = 'https://api.github.com/repos/' + config.username + '/' + config.repo + '/issues';

/**
* 读取 sitemap 文件
* 远程 sitemap 文件获取可参考 https://www.npmjs.com/package/sitemapper
*/
const sitemapXmlReader = (file) => {
  try {
    const data = fs.readFileSync(file, 'utf8');
    const sitemap = xmlParser(data);
    let ret = [];
    sitemap.root.children.forEach(function (url) {
      const loc = url.children.find(function (item) {
        return item.name === 'loc';
      });
      if (!loc) {
        return false;
      }
      const title = url.children.find(function (item) {
        return item.name === 'title';
      });

      ret.push({
        url: loc.content,
        title: title.content
      });
    });
    return ret;
  } catch (e) {
    return [];
  }
};

// 获取 gitalk 使用的 id
const getGitalkId = ({
  url: requrl
}) => {
  const link = url.parse(requrl);
  // 链接不存在，不需要初始化
  if (!link || !link.pathname) {
    return false;
  }
  return link.pathname;
};

/**
* 通过以请求判断是否已经初始化
* @param {string} gitalk 初始化的id
* @return {[boolean, boolean]} 第一个值表示是否出错，第二个值 false 表示没初始化， true 表示已经初始化
*/
const getIsInitByRequest = (id) => {
  const options = {
    headers: {
      'Authorization': 'token ' + config.token,
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36',
      'Accept': 'application/json'
    },
    url: api + '?labels=' + id + ',Gitalk',
    method: 'GET'
  };
  return new Promise((resolve) => {
    request(options, function (err, response, body) {
      if (err) {
        return resolve([err, false]);
      }
      if (response.statusCode != 200) {
        return resolve([response, false]);
      }
      const res = JSON.parse(body);
      if (res.length > 0) {
        return resolve([false, true]);
      }
      return resolve([false, false]);
    });
  });
};

/**
* 通过缓存判断是否已经初始化
* @param {string} gitalk 初始化的id
* @return {boolean} false 表示没初始化， true 表示已经初始化
*/
const getIsInitByCache = (() => {
  // 判断缓存文件是否存在
  let gitalkCache = false;
  try {
    gitalkCache = require(config.gitalkCacheFile);
  } catch (e) {}
  return function (id) {
    if (!gitalkCache) {
      return false;
    }
    if (gitalkCache.find(({
        id: itemId
      }) => (itemId === id))) {
      return true;
    }
    return false;
  };
})();

// 根据缓存，判断链接是否已经初始化
// 第一个值表示是否出错，第二个值 false 表示没初始化， true 表示已经初始化
const idIsInit = async (id) => {
  if (!config.cache) {
    return await getIsInitByRequest(id);
  }
  // 如果通过缓存查询到的数据是未初始化，则再通过请求判断是否已经初始化，防止多次初始化
  if (getIsInitByCache(id) === false) {
    return await getIsInitByRequest(id);
  }
  return [false, true];
};

// 初始化
const gitalkInit = ({
  url,
  id,
  title
}) => {
  //创建issue
  const reqBody = {
    'title': title,
    'labels': [id, 'Gitalk'],
    'body': url
  };

  const options = {
    headers: {
      'Authorization': 'token ' + config.token,
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36',
      'Accept': 'application/json',
      'Content-Type': 'application/json;charset=UTF-8'
    },
    url: api,
    body: JSON.stringify(reqBody),
    method: 'POST'
  };
  return new Promise((resolve) => {
    request(options, function (err, response, body) {
      if (err) {
        return resolve([err, false]);
      }
      if (response.statusCode != 201) {
        return resolve([response, false]);
      }
      return resolve([false, true]);
    });
  });
};


/**
* 写入内容
* @param {string} fileName 文件名
* @param {string} content 内容
*/
const write = async (fileName, content, flag = 'w+') => {
  return new Promise((resolve) => {
    fs.open(fileName, flag, function (err, fd) {
      if (err) {
        resolve([err, false]);
        return;
      }
      fs.writeFile(fd, content, function (err) {
        if (err) {
          resolve([err, false]);
          return;
        }
        fs.close(fd, (err) => {
          if (err) {
            resolve([err, false]);
            return;
          }
        });
        resolve([false, true]);
      });
    });
  });
};

const init = async () => {
  console.log(config.sitemap);
  const urls = sitemapXmlReader(config.sitemap);
  // 报错的数据
  const errorData = [];
  // 已经初始化的数据
  const initializedData = [];
  // 成功初始化数据
  const successData = [];
  for (const item of urls) {
    const {
      url,
      title
    } = item;
    const id = getGitalkId({url});
    if (!id) {
      console.log(`id: 生成失败 [ ${id} ] `);
      errorData.push({
        ...item,
        info: 'id 生成失败',
      });
      continue;
    }
    const [err, res] = await idIsInit(id);
    if (err) {
      console.log(`Error: 查询评论异常 [ ${title} ] , 信息：`, err || '无');
      errorData.push({
        ...item,
        info: '查询评论异常',
      });
      continue;
    }
    if (res === true) {
      // console.log(`--- Gitalk 已经初始化 --- [ ${title} ] `);
      initializedData.push({
        id,
        url,
        title,
      });
      continue;
    }
    // console.log(`Gitalk 初始化开始... [ ${title} ] `);
    await wait(2000)
    const [e, r] = await gitalkInit({
      id,
      url,
      title,
    });
    if (e || !r) {
      console.log(`Error: Gitalk 初始化异常 [ ${title} ] , 信息：`, e || '无');
      errorData.push({
        ...item,
        info: '初始化异常',
      });
      // continue;
      break;
    }
    successData.push({
      id,
      url,
      title,
    });
    console.log(`Gitalk 初始化成功! [ ${title} ] - ${id} \n`);
    await write(config.gitalkCacheFile, `${id}`, null, 2);
    continue;
  }

  console.log(''); // 空输出，用于换行
  console.log('--------- 运行结果 ---------');
  console.log(''); // 空输出，用于换行
  if (errorData.length !== 0) {
    console.log(`报错数据： ${errorData.length} 条。参考文件 ${config.gitalkErrorFile}。`);
    await write(config.gitalkErrorFile, JSON.stringify(errorData, null, 2));
  }
  console.log(`本次成功： ${successData.length} 条。`);

  // 写入缓存
  if (config.cache) {
    console.log(`写入缓存： ${(initializedData.length + successData.length)} 条，已初始化 ${initializedData.length} 条，本次成功： ${successData.length} 条。参考文件 ${config.gitalkCacheFile}。`);
    await write(config.gitalkCacheFile, JSON.stringify(initializedData.concat(successData), null, 2));
  } else {
    console.log(`已初始化： ${initializedData.length} 条。`);
  }
};

init();