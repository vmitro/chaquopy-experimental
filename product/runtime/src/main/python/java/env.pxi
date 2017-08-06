# Friendlier interface to JNIEnv:
#   * Checks for and raises Java exceptions.
#   * Uses JNIRef everywhere.
#   * Where JNIEnv returns a jboolean, CQPEnv returns a Python bool.
#   * Where JNIEnv accepts a jchar, CQPEnv accepts a single-character Python Unicode
#     or byte string, checking that the character is in the BMP. Where JNIEnv returns a jchar,
#     CQPEnv returns a Python Unicode string.
#   * Where JNIEnv accepts a char*, CQPEnv accepts a Python Unicode and byte string,
#
cdef class CQPEnv(object):
    cdef JNIEnv *j_env

    def __init__(self):
        self.j_env = get_jnienv()

    # All common notations may be used, including '.' or '/' to separate package names, and
    # optional "L" and ";" at start and end. Use a leading "[" for array types. Raises the same
    # exceptions as Class.forName.
    cpdef LocalRef FindClass(self, cls):
        name = cls if isinstance(cls, six.string_types) else java.jni_sig(cls)
        name = name.replace(".", "/")
        if name.startswith("L") and name.endswith(";"):
            name = name[1:-1]
        result = self.adopt(self.j_env[0].FindClass(self.j_env, str_for_c(name)))
        if not result:
            self.expect_exception(f"FindClass failed for {name}")
        return result

    cdef LocalRef ExceptionOccurred(self):
        return self.adopt(self.j_env[0].ExceptionOccurred(self.j_env))

    cdef ExceptionClear(self):
        self.j_env[0].ExceptionClear(self.j_env)

    cdef IsSameObject(self, JNIRef ref1, JNIRef ref2):
        return bool(self.j_env[0].IsSameObject(self.j_env, ref1.obj, ref2.obj))

    cdef IsInstanceOf(self, JNIRef obj, JNIRef j_klass):
        return bool(self.j_env[0].IsInstanceOf(self.j_env, obj.obj, j_klass.obj))

    cdef jmethodID GetMethodID(self, JNIRef j_klass, name, definition) except NULL:
        cdef jmethodID result = self.j_env[0].GetMethodID \
            (self.j_env, j_klass.obj, str_for_c(name), str_for_c(definition))
        if result == NULL:
            self.expect_exception(f'GetMethodID failed for {name}, {definition}')
        return result

    cdef jfieldID GetFieldID(self, JNIRef j_klass, name, definition) except NULL:
        cdef jfieldID result = self.j_env[0].GetFieldID \
            (self.j_env, j_klass.obj, str_for_c(name), str_for_c(definition))
        if result == NULL:
            self.expect_exception(f'GetFieldID failed for {name}, {definition}')
        return result

    cdef jmethodID GetStaticMethodID(self, JNIRef j_klass, name, definition) except NULL:
        cdef jmethodID result = self.j_env[0].GetStaticMethodID \
            (self.j_env, j_klass.obj, str_for_c(name), str_for_c(definition))
        if result == NULL:
            self.expect_exception(f'GetStaticMethodID failed for {name}, {definition}')
        return result

    cdef jfieldID GetStaticFieldID(self, JNIRef j_klass, name, definition) except NULL:
        cdef jfieldID result = self.j_env[0].GetStaticFieldID \
            (self.j_env, j_klass.obj, str_for_c(name), str_for_c(definition))
        if result == NULL:
            self.expect_exception(f'GetStaticFieldID failed for {name}, {definition}')
        return result

    cdef GetArrayLength(self, JNIRef array):
        return self.j_env[0].GetArrayLength(self.j_env, array.obj)

    cdef LocalRef NewBooleanArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewBooleanArray(self.j_env, length))
    cdef LocalRef NewByteArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewByteArray(self.j_env, length))
    cdef LocalRef NewShortArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewShortArray(self.j_env, length))
    cdef LocalRef NewIntArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewIntArray(self.j_env, length))
    cdef LocalRef NewLongArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewLongArray(self.j_env, length))
    cdef LocalRef NewFloatArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewFloatArray(self.j_env, length))
    cdef LocalRef NewDoubleArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewDoubleArray(self.j_env, length))
    cdef LocalRef NewCharArray(self, length):
        return self.adopt_notnull(self.j_env[0].NewCharArray(self.j_env, length))
    cdef LocalRef NewObjectArray(self, length, JNIRef j_klass):
        return self.adopt_notnull(self.j_env[0].NewObjectArray(self.j_env, length, j_klass.obj, NULL))

    cdef GetBooleanArrayElement(self, JNIRef array, index):
        cdef jboolean j_value = 0
        self.j_env[0].GetBooleanArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return bool(j_value)
    cdef GetByteArrayElement(self, JNIRef array, index):
        cdef jbyte j_value = 0
        self.j_env[0].GetByteArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetShortArrayElement(self, JNIRef array, index):
        cdef jshort j_value = 0
        self.j_env[0].GetShortArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetIntArrayElement(self, JNIRef array, index):
        cdef jint j_value = 0
        self.j_env[0].GetIntArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetLongArrayElement(self, JNIRef array, index):
        cdef jlong j_value = 0
        self.j_env[0].GetLongArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetFloatArrayElement(self, JNIRef array, index):
        cdef jfloat j_value = 0
        self.j_env[0].GetFloatArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetDoubleArrayElement(self, JNIRef array, index):
        cdef double j_value = 0
        self.j_env[0].GetDoubleArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return j_value
    cdef GetCharArrayElement(self, JNIRef array, index):
        cdef jchar j_value = 0
        self.j_env[0].GetCharArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
        return six.unichr(j_value)
    cdef LocalRef GetObjectArrayElement(self, JNIRef array, index):
        result = self.adopt(self.j_env[0].GetObjectArrayElement(self.j_env, array.obj, index))
        self.check_exception()
        return result

    cdef SetBooleanArrayElement(self, JNIRef array, index, value):
        cdef jboolean j_value = value
        self.j_env[0].SetBooleanArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetByteArrayElement(self, JNIRef array, index, value):
        cdef jbyte j_value = value
        self.j_env[0].SetByteArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetShortArrayElement(self, JNIRef array, index, value):
        cdef jshort j_value = value
        self.j_env[0].SetShortArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetIntArrayElement(self, JNIRef array, index, value):
        cdef jint j_value = value
        self.j_env[0].SetIntArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetLongArrayElement(self, JNIRef array, index, value):
        cdef jlong j_value = value
        self.j_env[0].SetLongArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetFloatArrayElement(self, JNIRef array, index, value):
        check_range_float32(value)
        cdef jfloat j_value = value
        self.j_env[0].SetFloatArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetDoubleArrayElement(self, JNIRef array, index, value):
        cdef jdouble j_value = value
        self.j_env[0].SetDoubleArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetCharArrayElement(self, JNIRef array, index, value):
        check_range_char(value)
        cdef jchar j_value = ord(value)
        self.j_env[0].SetCharArrayRegion(self.j_env, array.obj, index, 1, &j_value)
        self.check_exception()
    cdef SetObjectArrayElement(self, JNIRef array, index, JNIRef value):
        self.j_env[0].SetObjectArrayElement(self.j_env, array.obj, index, value.obj)
        self.check_exception()

    cdef LocalRef adopt_notnull(self, jobject j_obj):
        if not j_obj:
            self.expect_exception("NULL object")
        return self.adopt(j_obj)

    cdef expect_exception(self, msg):
        expect_exception(self.j_env, msg)

    cdef check_exception(self):
        check_exception(self.j_env)

    cdef LocalRef adopt(self, jobject j_obj):
        return LocalRef.adopt(self.j_env, j_obj)


cdef GlobalRef j_System
cdef jmethodID mid_identityHashCode = NULL

cdef class JNIRef(object):
    # Member variables declared in .pxd

    def __init__(self):
        telem[self.__class__.__name__] += 1

    def __dealloc__(self):
        telem[self.__class__.__name__] -= 1

    def __repr__(self):
        return f'<{type(self).__name__} obj=0x{<uintptr_t>self.obj:x}>'

    def __richcmp__(self, JNIRef other, op):
        if op == 2:  # __eq__
            return CQPEnv().IsSameObject(self, other)
        elif op == 3:  # __ne__
            return not self.__richcmp__(other, 2)
        else:
            raise NotImplementedError()

    def __hash__(self):
        global j_System, mid_identityHashCode
        env = CQPEnv()
        if not j_System:
            j_System = env.FindClass("Ljava/lang/System;").global_ref()
            mid_identityHashCode = env.GetStaticMethodID \
                (j_System, "identityHashCode", "(Ljava/lang/Object;)I")
        return env.j_env[0].CallStaticIntMethod \
            (env.j_env, j_System.obj, mid_identityHashCode, self.obj)

    def __nonzero__(self):      # Python 2 name
        return self.obj != NULL
    def __bool__(self):         # Python 3 name
        return self.obj != NULL

    cdef GlobalRef global_ref(self):
        raise NotImplementedError()

    cdef jobject return_ref(self, JNIEnv *env):
        """Returns a new local reference suitable for returning from a `native` method or otherwise
        outliving the JNIRef object."""
        if self:
            return env[0].NewLocalRef(env, self.obj)
        else:
            return NULL


cdef class GlobalRef(object):
    @staticmethod
    cdef GlobalRef create(JNIEnv *env, jobject obj):
        cdef GlobalRef gr = GlobalRef()
        if obj:
            gr.obj = env[0].NewGlobalRef(env, obj)
        return gr

    def __dealloc__(self):
        cdef JNIEnv *j_env
        if self.obj:
            j_env = get_jnienv()
            j_env[0].DeleteGlobalRef(j_env, self.obj)
        self.obj = NULL
        # The __dealloc__() method of the superclass will be called automatically.

    cdef GlobalRef global_ref(self):
        return self


cdef class LocalRef(JNIRef):
    # Member variables declared in .pxd

    @staticmethod
    cdef LocalRef create(JNIEnv *env, jobject obj):
        return LocalRef.adopt(env,
                              env[0].NewLocalRef(env, obj) if obj else NULL)

    # This should not be used for parameters of `native` methods: on Android, that causes the
    # warning "Attempt to remove non-JNI local reference". Use `LocalRef.create` instead.
    @staticmethod
    cdef LocalRef adopt(JNIEnv *env, jobject obj):
        cdef LocalRef lr = LocalRef()
        lr.env = env
        lr.obj = obj
        return lr

    def __dealloc__(self):
        if self.obj:
            self.env[0].DeleteLocalRef(self.env, self.obj)
        self.obj = NULL
        # The __dealloc__() method of the superclass will be called automatically.

    cdef GlobalRef global_ref(self):
        return GlobalRef.create(self.env, self.obj)
