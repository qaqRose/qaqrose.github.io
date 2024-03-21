spring cloud 的配置刷新流程

添加`@RefreshScope` 可以使bean在运行时刷新，但是具体的流程是怎么样的呢

```java
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Scope("refresh")
@Documented
public @interface RefreshScope {

	/**
	 * Alias for {@link Scope#proxyMode}.
	 * @see Scope#proxyMode()
	 * @return proxy mode
	 */
	@AliasFor(annotation = Scope.class)
	ScopedProxyMode proxyMode() default ScopedProxyMode.TARGET_CLASS;

}

```

让我们深入了解一下