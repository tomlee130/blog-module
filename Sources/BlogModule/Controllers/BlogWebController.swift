//
//  BlogFrontendView.swift
//  BlogModule
//
//  Created by Tibor Bodecs on 2020. 11. 06..
//

import FeatherCore

struct BlogWebController {

    // MARK: - response hooks

    func authorResponseHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req

        return BlogAuthorModel.queryJoinVisibleMetadata(path: req.url.path, on: req.db)
            .with(\.$links)
            .first()
            .flatMap { author  in
                guard let author = author else {
                    return req.eventLoop.future(nil)
                }
                return author.$posts.query(on: req.db)
                    .joinPublicMetadata()
                    .with(\.$categories)
                    .all()
                    .flatMap { posts in
                        req.tau.render(template: "Blog/Author", context: [
                            "author": author.encodeToTemplateData(),
                            "posts": .array(posts.map { $0.templateDataWithJoinedMetadata }),
                        ])
                    }
                    .encodeOptionalResponse(for: req)
            }
    }

    func categoryResponseHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req
        
        return BlogCategoryModel.queryJoinVisibleMetadata(path: req.url.path, on: req.db)
            .first()
            .flatMap { category  in
                guard let category = category else {
                    return req.eventLoop.future(nil)
                }
                return category.$posts.query(on: req.db)
                    .joinPublicMetadata()
                    .with(\.$categories)
                    .all()
                    .flatMap { posts in
                        req.tau.render(template: "Blog/Category", context: [
                            "category": category.encodeToTemplateData(),
                            "posts": .array(posts.map { $0.templateDataWithJoinedMetadata }),
                        ])
                    }
                    .encodeOptionalResponse(for: req)
            }
    }

    func postResponseHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req

        return BlogPostModel.queryJoinVisibleMetadata(path: req.url.path, on: req.db)
            .with(\.$categories)
            .with(\.$authors) { $0.with(\.$links) }
            .first()
            .flatMap { post  in
                guard let post = post else {
                    return req.eventLoop.future(nil)
                }
                return post.filter(post.content ?? "", req: req)
                    .flatMap { content -> EventLoopFuture<View> in
                        /// render the post with the filtered content
                        var ctx = post.templateDataWithJoinedMetadata.dictionary!
                        ctx["content"] = .string(content)
                        return req.tau.render(template: "Blog/Post", context: ["post": ctx.templateData])
                    }
                    .encodeOptionalResponse(for: req)
            }
    }

    // MARK: - page hooks

    /// renders the [blog-home-page] content
    func blogHomePageHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req
        let metadata = args.metadata

        return BlogPostModel
            .queryJoinPublicMetadata(on: req.db)
            .limit(17)
            .with(\.$categories)
            .all()
            .flatMap { posts in
                req.tau.render(template: "Blog/Home", context: [
                    "metadata": metadata.encodeToTemplateData(),
                    "posts": .array(posts.map(\.templateDataWithJoinedMetadata))
                ])
            }
            .encodeOptionalResponse(for: req)
    }

    /// renders the [blog-categories-page] content
    func categoriesPageHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req
        let metadata = args.metadata

        return BlogCategoryModel.queryJoinPublicMetadata(on: req.db)
            .all()
            .flatMap { categories in
                req.tau.render(template: "Blog/Categories", context: [
                    "metadata": metadata.encodeToTemplateData(),
                    "categories": .array(categories.map { $0.templateDataWithJoinedMetadata }),
                ])
            }
            .encodeOptionalResponse(for: req)
    }

    /// renders the [blog-authors-page] content
    func authorsPageHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req
        let metadata = args.metadata

        return BlogAuthorModel.queryJoinPublicMetadata(on: req.db)
            .all()
            .flatMap { authors in
                req.tau.render(template: "Blog/Authors", context: [
                    "metadata": metadata.encodeToTemplateData(),
                    "authors": .array(authors.map { $0.templateDataWithJoinedMetadata }),
                ])
            }
            .encodeOptionalResponse(for: req)
    }

    /// renders the [blog-posts-page] content
    func postsPageHook(args: HookArguments) -> EventLoopFuture<Response?> {
        let req = args.req
        let metadata = args.metadata

        return ListLoader<BlogPostModel>(beforeQuery: { _, qb in
            BlogPostModel.queryJoinPublicMetadata(on: req.db).with(\.$categories)
        }).paginateAll(req).flatMap { pagination in
            req.tau.render(template: "Blog/Posts", context: [
                "metadata": metadata.encodeToTemplateData(),
                "posts": .array(pagination.items.map { $0.templateDataWithJoinedMetadata }),
                "pages": pagination.info.encodeToTemplateData(),
            ])
        }
        .encodeOptionalResponse(for: req)
    }
}
