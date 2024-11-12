---
title: ArrayList的扩容
layout: info
commentable: true
date: 2023-10-29
mathjax: true
mermaid: true
tags: [Java]
categories: 面试
description: 
---


# ArrayList 的扩容

ArrayList 可以说是应用最广泛的 Java 容器，所有的列表或者是数据遍历，
多多少少都可以看到它的身影 

今天我们来了解一下它扩容的过程，这里使用的 `Java 17` 版本的源码


## 程序实例

我们以一个简单的程序开始我们的源码学习之旅

```java
public class ResizeArrayList {
    /**
     * 限制 jvm 堆大小  -Xms50m -Xmx50m
     */
    public static void main(String[] args) {
        List list = new ArrayList();
        int count = 0;
        while (true) {
            list.add(count++);
        }
    }
}
```

如上程序中，我们创建了一个 ArrayList ，并不断往里面添加数据，直到 oom

需要注意添加 jvm 参数 `-Xms50m -Xmx50m`

启动程序，可以看到控制台报错

![arraylist扩容报错](/images/arraylist-resize/oom.png)

因为不断往 list 中添加元素，ArrayList 由于容量不足，需要扩容，并最终在
向系统申请内存发生了 `OutOfMemoryError` 

所以从异常堆栈反推，刚好得到一条我们学习扩容的类方法路线

```java
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.base/java.util.Arrays.copyOf(Arrays.java:3512)
	at java.base/java.util.Arrays.copyOf(Arrays.java:3481)
	at java.base/java.util.ArrayList.grow(ArrayList.java:237)
	at java.base/java.util.ArrayList.grow(ArrayList.java:244)
	at java.base/java.util.ArrayList.add(ArrayList.java:454)
	at java.base/java.util.ArrayList.add(ArrayList.java:467)
	at collection.ResizeArrayList.main(ResizeArrayList.java:18)
```

## 扩容临界

可以看到，从容器扩容的流程是

`add() -> grow() -> Arrays.copyOf()`

我们先简单看看下 `add` 方法

```java
public boolean add(E e) {
    modCount++;                 // 修改次数 + 1
    add(e, elementData, size);  // 真正的添加元素方法
    return true;
}

private void add(E e, Object[] elementData, int s) {
    if (s == elementData.length)   // 1
        elementData = grow();
    elementData[s] = e;
    size = s + 1;
}
```

`modCount` 是列表结构化修改的次数，主要是用于判断并发操作导致数据不一致的情况，这里不展开了

`elementData` 是一个对象数据，真正存储元素的地方，`size` 是当前 list 的大小，相当于包含的元素数量

```java
transient Object[] elementData;   // 元素数组
private int size;                 // 容器大小

// 在 java.util.AbstractList 中
protected transient int modCount = 0;
```

接着看 `add(E e, Object[] elementData, int s)` 方法

在`代码1` 处，s表示添加元素的下标，等于元素数组的大小时，说明当前 elementData 的位置已经占满，需要进行扩容（调用 grow 方法）

否则直接将元素放置在 s 位置上，并对元素数量 size 加1

需要注意的时，如果使用无参构造函数`new ArrayList()` 或者参数为0如`new ArrayList(0)`

会将 elementData 初始化为一个空数组 `new Object[]{}`

```java
// 默认容量的空数组
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};

private static final Object[] EMPTY_ELEMENTDATA = {};

public ArrayList() {                // 无参构造函数
    this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
}

public ArrayList(int initialCapacity) {
    if (initialCapacity > 0) {
        this.elementData = new Object[initialCapacity];
    } else if (initialCapacity == 0)          // 初始阈值为0
        this.elementData = EMPTY_ELEMENTDATA; 
    } else {
        throw new IllegalArgumentException("Illegal Capacity: "+
                                            initialCapacity);
    }
}
```

## 扩容

接着看 grow 方法

```java

private static final int DEFAULT_CAPACITY = 10;

private Object[] grow() {
    return grow(size + 1);   // 2
}

private Object[] grow(int minCapacity) {
    int oldCapacity = elementData.length;
    //
    if (oldCapacity > 0 || elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {  // 3
        int newCapacity = ArraysSupport.newLength(oldCapacity,        // 4
                minCapacity - oldCapacity, /* minimum growth */
                oldCapacity >> 1           /* preferred growth */);
        return elementData = Arrays.copyOf(elementData, newCapacity);
    } else {
        return elementData = new Object[Math.max(DEFAULT_CAPACITY, minCapacity)];
    }
}

```

在`代码2` 出，直接将当前容器大小+1作为最小容量参数传入

在 `grow(int minCapacity)` 这个扩容函数有主要有两个代码分支，

分别表示第一次扩容，和非第一次扩容 
（注：这里的第一次是指初始为空数组的时候，如果指定了容量，则第一次扩容也不会走这个分支）

看`代码3` 处的判断，当发生第一次扩容时，elementData是默认空数组（DEFAULTCAPACITY_EMPTY_ELEMENTDATA）
或者列表容量为0（oldCapacity），所以直接对 elementData 赋值即可完成扩容

由于第一次扩容minCapacity小于DEFAULT_CAPACITY，所以第一次扩容后，列表容量大小为10

否则需要通过 `ArraysSupport.newLength` 计算新的容量，并通过 copyOf 复制数组进行扩容


```java
public static final int SOFT_MAX_ARRAY_LENGTH = Integer.MAX_VALUE - 8;

/**
 * @param oldLength  数组当前长度
 * @param minGrowth  最小增长量
 * @param prefGrowth 首选增长量
 */
public static int newLength(int oldLength, int minGrowth, int prefGrowth) {
    // prefLength 表示可能的最大数组长度
    int prefLength = oldLength + Math.max(minGrowth, prefGrowth); // might overflow
    // 如果长度在正常范围，就直接使用
    if (0 < prefLength && prefLength <= SOFT_MAX_ARRAY_LENGTH) {
        return prefLength;
    } else {
        // 抽出一个方法
        return hugeLength(oldLength, minGrowth);
    }
}

/**
 * @param oldLength  数组当前长度
 * @param minGrowth  最小增长量
 */
private static int hugeLength(int oldLength, int minGrowth) {
        int minLength = oldLength + minGrowth;
        // 这里发生了溢出，变成了负数，直接报错
        if (minLength < 0) { // overflow
            throw new OutOfMemoryError(
                "Required array length " + oldLength + " + " + minGrowth + " is too large");
        } else if (minLength <= SOFT_MAX_ARRAY_LENGTH) {
            return SOFT_MAX_ARRAY_LENGTH;
        } else {
            return minLength;
        }
    }
```

通过 `newLength` 计算得出新数组的长度，一般是原来的1.5倍

在`代码4` 中，这里的 `oldCapacity >> 1`使用位运算，等于 `oldCapacity / 2` 得到0.5原来的大小

在不发生int数量溢出的情况，扩容旧数组为原来的1.5倍

最后的数组扩容则是使用 jvm底层的能力

```java
/**
 * @param original  原数组
 * @param newLength  复制后的数组的长度
 */
public static <T> T[] copyOf(T[] original, int newLength) {
    return (T[]) copyOf(original, newLength, original.getClass());
}

/**
 * @param original  原数组
 * @param newLength  复制后的数组的长度
 * @param newType    新数组元素的类型
 * 
 */
public static <T,U> T[] copyOf(U[] original, int newLength, Class<? extends T[]> newType) {
    // 初始化新数组
    @SuppressWarnings("unchecked")
    T[] copy = ((Object)newType == (Object)Object[].class)
        ? (T[]) new Object[newLength]
        : (T[]) Array.newInstance(newType.getComponentType(), newLength);

    // 将 original数组 复制到 copy数组
    System.arraycopy(original, 0, copy, 0,
                        Math.min(original.length, newLength));
    return copy;
}
```
## 扩展

除了 `add(E e)` 方法会触发扩容，还有其他方法也会

![arraylist扩容的扩展](/images/arraylist-resize/grow-extend.png)

但是主要是原理还是一样，所以这里不再展开说明，有兴趣可以自行查看


## 结论

1. ArrayList默认的无参构造函数初始化一个空的对象数组
2. 初次扩容发生在添加第一个元素时（在1的前提下），大小是10个元素
3. 后续扩容的大小为1.5倍
4. 最多能存储Integer.MAX_VALUE个元素

