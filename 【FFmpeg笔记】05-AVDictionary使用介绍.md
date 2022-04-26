# 【FFmpeg笔记】05-AVDictionary使用介绍

## 1. AVDictionary 介绍 ##

AVDictionary 是一种字典数据结构，可以简单理解为 key-value 集合。现在主要用于兼容 libav** 库，效率会比较低一些，官方推荐使用树形容器，见 tree.h 文件。

Audictionary 中的每个 item 可以当作为 AVDictionaryEntry 进行处理，AVDictionaryEntry 的声明如下：

```
typedef struct AVDictionaryEntry {
    char *key;
    char *value;
} AVDictionaryEntry;
```
.

## 2. 创建与销毁 ##
 
使用 av_dict_set() 方法创建实例：
使用 av_dict_free() 方法销毁实例：

```
AVDictionary *d = NULL;           // "create" an empty dictionary
av_dict_set(&d, "foo", "bar", 0); // add an entry

av_dict_free(&d);                  // release
```

av_dict_set() 方法会检查第一个参数(const AVDictionary *m)，如果为空，则自动分配一个 AVDictionary 对象。
.
## 3. 赋值 ##

使用 av_dict_set() / av_dict_set_int() 方法赋值。

```
/**

* Set the given entry in *pm, overwriting an existing entry.

* 

* Note: If AV_DICT_DONT_STRDUP_KEY or AV_DICT_DONT_STRDUP_VAL is set,

* these arguments will be freed on error.

* 

* Warning: Adding a new entry to a dictionary invalidates all existing entries

* previously returned with av_dict_get.

* 

* @param pm pointer to a pointer to a dictionary struct. If *pm is NULL

* a dictionary struct is allocated and put in *pm.

* @param key entry key to add to *pm (will either be av_strduped or added as a new key depending on flags)

* @param value entry value to add to *pm (will be av_strduped or added as a new key depending on flags).

*     Passing a NULL value will cause an existing entry to be deleted.

* @return >= 0 on success otherwise an error code <0
  */
  int av_dict_set(AVDictionary **pm, const char *key, const char *value, int flags);

/**

* Convenience wrapper for av_dict_set that converts the value to a string
* and stores it.
* * Note: If AV_DICT_DONT_STRDUP_KEY is set, key will be freed on error.
    */
    int av_dict_set_int(AVDictionary **pm, const char *key, int64_t value, int flags);
```
- pm 参数：字典的指针地址，如果 pm 参数为空，则自动分配一个对象并存储在 pm 中。
- key 参数：指定键，如果指定的键已经存在，则覆盖
- value 参数：指定值，如果传递 NULL，则删除该 AVDictionaryEntry
    .
## 4. 取值 ##

使用 av_dict_get() 方法取值。

```
/**

* Get a dictionary entry with matching key.
* * The returned entry key or value must not be changed, or it will
* cause undefined behavior.
* * To iterate through all the dictionary entries, you can set the matching key
* to the null string "" and set the AV_DICT_IGNORE_SUFFIX flag.
* * @param prev Set to the previous matching element to find the next.
*          If set to NULL the first matching element is returned.
* @param key matching key
* @param flags a collection of AV_DICT_* flags controlling how the entry is retrieved
* @return found entry or NULL in case no matching entry was found in the dictionary
  */
  AVDictionaryEntry *av_dict_get(const AVDictionary *m, const char *key,
  
                              const AVDictionaryEntry *prev, int flags);
```

- m 参数：字典指针；
- key 参数：要获取的 key的值；
- prev 参数：遍历的时候会用到；
- flags 参数：标记，有以下取值
- AV_DICT_MATCH_CASE ：表示匹配大小写，默认是大小写不敏感；
- AV_DICT_IGNORE_SUFFIX ：表示忽略后缀，即如果 dict 中有一个key是"abcd"，那么该函数的参数传递"abc"，也会返回"abcd"。在遍历的时候，参数 key 传的值为 “”，那么表示，不管是什么 dict 中有什么 key，都能匹配上。

av_dict_get 源码参考：

```
AVDictionaryEntry *av_dict_get(const AVDictionary *m, const char *key,
                               const AVDictionaryEntry *prev, int flags)
{
    unsigned int i, j;

    if (!m)
        return NULL;
    
    if (prev)
        i = prev - m->elems + 1;
    else
        i = 0;
    
    for (; i < m->count; i++) {
        const char *s = m->elems[i].key;
        if (flags & AV_DICT_MATCH_CASE)
            for (j = 0; s[j] == key[j] && key[j]; j++)
                ;
        else
            for (j = 0; av_toupper(s[j]) == av_toupper(key[j]) && key[j]; j++)
                ;
        if (key[j])
            continue;
        if (s[j] && !(flags & AV_DICT_IGNORE_SUFFIX))
            continue;
        return &m->elems[i];
    }
    return NULL;

}
```

使用示例：

```
AVDictionary *d = NULL;

//赋值
av_dict_set(&d, "name", "bassy", 0);
av_dict_set(&d, "age", "18", 0);

//取值
AVDictionaryEntry *pEntry;
pEntry = av_dict_get(d, "name", nullptr, 0);
if (pEntry) {
    LOGI("key=%s, value=%s", pEntry->key, pEntry->value);
}

//获取字典item数
LOGI("dictionary size=%d", av_dict_count(d));

av_dict_free(&d);
```
.

## 5. 获取数量 ##

使用 av_dict_count() 方法获取字典的 item 数：

```
/**

* Get number of entries in dictionary.

* 

* @param m dictionary

* @return  number of entries in dictionary
  */
  int av_dict_count(const AVDictionary *m);
```

## 6. 复制 ##

使用 av_dict_copy() 方法复制字典：

```
/**

* Copy entries from one AVDictionary struct into another.
* @param dst pointer to a pointer to a AVDictionary struct. If *dst is NULL,
*         this function will allocate a struct for you and put it in *dst
* @param src pointer to source AVDictionary struct
* @param flags flags to use when setting entries in *dst
* @note metadata is read using the AV_DICT_IGNORE_SUFFIX flag
* @return 0 on success, negative AVERROR code on failure. If dst was allocated
*  by this function, callers should free the associated memory.
  */
  int av_dict_copy(AVDictionary **dst, const AVDictionary *src, int flags);
```
  .
## 7. AVDictionary 遍历 ##

AVDictionary 的遍历方法如下：

```
AVDictionary* dictionary = ic->metadata;
AVDictionaryEntry *pEntry = nullptr;
while ((pEntry = av_dict_get(dictionary, "", pEntry, AV_DICT_IGNORE_SUFFIX))) {
    LOGI("metadata : %s=%s\n", pEntry->key, pEntry->value);
}
```
.
————————————————

版权声明：本文为CSDN博主「又吹风_Bassy」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/eieihihi/article/details/114502699