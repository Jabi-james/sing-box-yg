# Sing-box Two scripts

#### For related instructions and precautions, please refer to [Yongge Blog Instructions and Serv00 Video Tutorial](https://ygkkk.blogspot.com/2025/01/serv00.html)

#### Video tutorial:

[Serv00's most comprehensive proxy script: exclusive support for three IP custom installations, support for Proxyip+reverse generation IP, support for Argo temporary/fixed tunnels+CDN back to source; support for five nodes of Sing-box and Clash subscription configuration output](https://youtu.be/2VF9D6z2z7w)

[Serv00 free node final tutorial: Serv00 no longer needs to log in to SSH, deployment and liveness are integrated, exclusive support for Github, VPS, soft router multi-platform multi-account universal deployment, four major solutions always have one suitable for you](https://youtu.be/rYeX1iU_iZ0)

### 1. Serv00 local dedicated one-key script, supports random port generation and web page keep-alive mode. Shortcut: ```bash serv00.sh```
```
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)
```

### Preview of the Sing-box-serv00 script interface (Note: for viewing only)
![e8e20bb88b3812e88631d8d64d39f02](https://github.com/user-attachments/assets/0e375140-e5cd-46f0-8819-594c655618ba)

### 2. Serv00 multi-account automatic deployment script: serv00.yml (github only)

Create a private library, modify the parameters of the serv00.yml file, run github action, automatically remotely deploy and keep alive the nodes of a single or multiple Serv00 accounts

### 3. Serv00 multi-account automatic deployment script: kp.sh (for VPS and soft router)

Modify the parameters of the kp.sh file to automatically remotely deploy and keep alive nodes of single or multiple Serv00 accounts on multiple platforms. It cannot be used on serv00 locally. The default nano editing format

You can also manually put it in other directories and run it regularly with cron

```
curl -sSL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/kp.sh -o kp.sh && chmod +x kp.sh && nano kp.sh
```
Run ```bash kp.sh``` to test the effectiveness

### Note:

1. Both serv00.yml and kp.sh are "forced keep-alive scripts". Even if Serv00 clears all files on your server, as long as you connect successfully, the keep-alive script will be automatically installed to keep it alive

2. You can also not set a timer for github. Add a ```#``` character before the following two lines to block the scheduled operation. When you find that the node is invalid, you can start it once in actions

``` # schedule: ```

``` # - cron: '0 */4 * * *' ```

-----------------------------------------------------

### Thank you for the star in the upper right corner🌟
[![Stargazers over time](https://starchart.cc/yonggekkk/sing-box-yg.svg)](https://starchart.cc/yonggekkk/sing-box-yg)

---------------------------------------
#### Statement: All codes come from the integration of Github community and ChatGPT, [老王eooce](https://github.com/eooce/Sing-box/blob/test/sb_00.sh), [frankiejun](https://github.com/frankiejun/serv00-play/blob/main/start.sh)
