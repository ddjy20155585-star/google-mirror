// ========== Google Drive appDataFolder 配置同步模块 ==========
(function() {
    const SYNC_FILE_NAME = 'gm_config.json';
    const STORAGE_TOKEN = 'gm_token';
    const SYNC_KEYS = [
        'gm_theme',      // 深色模式
        'gm_ui_mode',    // 极简/完整模式
        'gm_history'     // 搜索历史
    ];

    function safeGet(key, def) {
        try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : def; }
        catch(e) { return def; }
    }
    function safeSet(key, val) {
        try { localStorage.setItem(key, JSON.stringify(val)); } catch(e) {}
    }
    function getToken() {
        return safeGet(STORAGE_TOKEN, null);
    }

    // 从 appDataFolder 查找配置文件
    async function findConfigFile(token) {
        const res = await fetch(
            'https://www.googleapis.com/drive/v3/files?' +
            'spaces=appDataFolder&' +
            'q=' + encodeURIComponent("name='" + SYNC_FILE_NAME + "'") +
            '&fields=files(id,name)',
            { headers: { Authorization: 'Bearer ' + token } }
        );
        if (!res.ok) return null;
        const data = await res.json();
        return (data.files && data.files[0]) ? data.files[0] : null;
    }

    // 上传配置到 appDataFolder
    async function uploadConfig(token, config) {
        const metadata = { name: SYNC_FILE_NAME, mimeType: 'application/json' };
        const boundary = '-------314159265358979323846';
        const delimiter = "\r\n--" + boundary + "\r\n";
        const closeDelim = "\r\n--" + boundary + "--";
        const body =
            delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.stringify(metadata) +
            delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.stringify(config) +
            closeDelim;

        const res = await fetch(
            'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name',
            {
                method: 'POST',
                headers: {
                    Authorization: 'Bearer ' + token,
                    'Content-Type': 'multipart/related; boundary="' + boundary + '"'
                },
                body: body
            }
        );
        if (!res.ok) {
            const err = await res.text();
            throw new Error('上传失败 ' + res.status + ': ' + err);
        }
        return res.json();
    }

    // 从 appDataFolder 下载配置
    async function downloadConfig(token) {
        const file = await findConfigFile(token);
        if (!file) return null;
        const res = await fetch(
            'https://www.googleapis.com/drive/v3/files/' + file.id + '?alt=media',
            { headers: { Authorization: 'Bearer ' + token } }
        );
        if (!res.ok) return null;
        return res.json();
    }

    // 收集本地配置
    function collectLocalConfig() {
        const config = {};
        SYNC_KEYS.forEach(key => {
            const val = safeGet(key, null);
            if (val !== null) config[key] = val;
        });
        return config;
    }

    // 应用云端配置到本地
    function applyConfig(config) {
        if (!config) return;
        SYNC_KEYS.forEach(key => {
            if (config[key] !== undefined) {
                safeSet(key, config[key]);
            }
        });
    }

    // ========== 对外接口 ==========
    window.gmSync = {
        push: async function() {
            const token = getToken();
            if (!token) return false;
            try {
                const config = collectLocalConfig();
                await uploadConfig(token, config);
                return true;
            } catch(e) {
                console.warn('配置上传失败：', e);
                return false;
            }
        },

        pull: async function() {
            const token = getToken();
            if (!token) return null;
            try {
                const config = await downloadConfig(token);
                if (config) applyConfig(config);
                return config;
            } catch(e) {
                console.warn('配置拉取失败：', e);
                return null;
            }
        },

        sync: async function() {
            const token = getToken();
            if (!token) return false;
            try {
                const remote = await downloadConfig(token);
                const local = collectLocalConfig();
                if (remote && Object.keys(remote).length > 0) {
                    applyConfig(remote);
                } else {
                    await uploadConfig(token, local);
                }
                return true;
            } catch(e) {
                console.warn('配置同步失败：', e);
                return false;
            }
        }
    };
})();